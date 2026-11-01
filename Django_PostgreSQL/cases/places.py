"""Geocoding proxy.

The Flutter apps never see the Goong REST key. This module calls Goong when
``GOONG_API_KEY`` is configured, and falls back to Nominatim otherwise so the
map picker keeps working before the Goong key exists.

Endpoints (mounted at ``/api/places/``):

* ``GET /autocomplete?input=...&limit=5``
* ``GET /detail?place_id=...``
* ``GET /reverse?lat=...&lng=...``
"""

from __future__ import annotations

import hashlib
import json
import logging
import threading
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from django.conf import settings
from django.core.cache import cache
from django.http import JsonResponse

logger = logging.getLogger(__name__)

GOONG_BASE = 'https://rsapi.goong.io'
NOMINATIM_BASE = 'https://nominatim.openstreetmap.org'
NOMINATIM_USER_AGENT = 'school-violation-detector/1.0 (student project)'
NOMINATIM_MIN_INTERVAL = 1.0

_nominatim_lock = threading.Lock()
_nominatim_last_request = 0.0


def _goong_key() -> str:
    return (getattr(settings, 'GOONG_API_KEY', '') or '').strip()


def _fetch_json(url: str, *, use_nominatim: bool = False) -> dict | list:
    # Goong also rejects Python's default urllib User-Agent with HTTP 403.
    # Send an explicit UA for both providers.
    headers = {
        'Accept': 'application/json',
        'User-Agent': NOMINATIM_USER_AGENT,
    }
    if use_nominatim:
        headers['Accept-Language'] = 'vi'

    request = Request(url, headers=headers)
    with urlopen(request, timeout=10) as response:
        payload = response.read().decode('utf-8')
    return json.loads(payload)


def _wait_for_nominatim() -> None:
    """Keeps Nominatim usage under one request per second."""
    global _nominatim_last_request
    with _nominatim_lock:
        elapsed = time.monotonic() - _nominatim_last_request
        if elapsed < NOMINATIM_MIN_INTERVAL:
            time.sleep(NOMINATIM_MIN_INTERVAL - elapsed)
        _nominatim_last_request = time.monotonic()


def _upstream_error(error: Exception) -> JsonResponse:
    logger.warning('Places upstream failed: %s', error)
    if isinstance(error, HTTPError) and error.code == 429:
        message = 'Dịch vụ địa chỉ đang bị giới hạn. Vui lòng thử lại sau.'
    else:
        message = 'Không kết nối được dịch vụ địa chỉ.'
    return JsonResponse({'error': message}, status=502)


def _parse_limit(raw: str | None, default: int = 5) -> int:
    try:
        value = int(raw or default)
    except (TypeError, ValueError):
        value = default
    return max(1, min(value, 10))


def autocomplete(request):
    if request.method != 'GET':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    query = (request.GET.get('input') or '').strip()
    limit = _parse_limit(request.GET.get('limit'))
    if len(query) < 2:
        return JsonResponse({'provider': 'none', 'predictions': []})

    query_hash = hashlib.sha256(
        f'{query.lower()}:{limit}'.encode('utf-8')
    ).hexdigest()[:20]
    cache_key = f'places:autocomplete:{query_hash}'
    cached = cache.get(cache_key)
    if cached is not None:
        return JsonResponse(cached)

    goong_key = _goong_key()
    try:
        if goong_key:
            params = urlencode(
                {'input': query, 'limit': limit, 'api_key': goong_key}
            )
            data = _fetch_json(f'{GOONG_BASE}/place/autocomplete?{params}')
            predictions = []
            for item in data.get('predictions', []):
                structured = item.get('structured_formatting') or {}
                predictions.append(
                    {
                        'place_id': item.get('place_id', ''),
                        'description': item.get('description', ''),
                        'main_text': structured.get('main_text', ''),
                        'secondary_text': structured.get('secondary_text', ''),
                    }
                )
            payload = {'provider': 'goong', 'predictions': predictions}
        else:
            _wait_for_nominatim()
            params = urlencode(
                {
                    'format': 'jsonv2',
                    'q': query,
                    'limit': limit,
                    'accept-language': 'vi',
                    'countrycodes': 'vn',
                }
            )
            data = _fetch_json(
                f'{NOMINATIM_BASE}/search?{params}', use_nominatim=True
            )
            predictions = []
            for item in data if isinstance(data, list) else []:
                try:
                    lat = float(item['lat'])
                    lng = float(item['lon'])
                except (KeyError, TypeError, ValueError):
                    continue
                display_name = (item.get('display_name') or '').strip()
                if not display_name:
                    continue
                predictions.append(
                    {
                        'place_id': '',
                        'description': display_name,
                        'main_text': display_name,
                        'secondary_text': '',
                        'lat': lat,
                        'lng': lng,
                    }
                )
            payload = {'provider': 'nominatim', 'predictions': predictions}
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        return _upstream_error(error)

    cache.set(cache_key, payload, 60)
    return JsonResponse(payload)


def detail(request):
    if request.method != 'GET':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    place_id = (request.GET.get('place_id') or '').strip()
    if not place_id:
        return JsonResponse({'error': 'Thiếu place_id.'}, status=400)

    goong_key = _goong_key()
    if not goong_key:
        return JsonResponse(
            {'error': 'Goong chưa được cấu hình trên máy chủ.'}, status=503
        )

    cache_key = f'places:detail:{place_id}'
    cached = cache.get(cache_key)
    if cached is not None:
        return JsonResponse(cached)

    try:
        params = urlencode({'place_id': place_id, 'api_key': goong_key})
        data = _fetch_json(f'{GOONG_BASE}/place/detail?{params}')
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        return _upstream_error(error)

    result = data.get('result') or {}
    geometry = result.get('geometry') or {}
    location = geometry.get('location') or {}
    if location.get('lat') is None or location.get('lng') is None:
        return JsonResponse(
            {'error': 'Không tìm thấy toạ độ cho địa chỉ này.'}, status=404
        )

    payload = {
        'result': {
            'lat': location.get('lat'),
            'lng': location.get('lng'),
            'formatted_address': result.get('formatted_address')
            or result.get('name', ''),
        }
    }
    cache.set(cache_key, payload, 60 * 60 * 24)
    return JsonResponse(payload)


def reverse(request):
    if request.method != 'GET':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        latitude = float(request.GET.get('lat', ''))
        longitude = float(request.GET.get('lng', ''))
    except (TypeError, ValueError):
        return JsonResponse({'error': 'Toạ độ không hợp lệ.'}, status=400)

    if not -90 <= latitude <= 90 or not -180 <= longitude <= 180:
        return JsonResponse({'error': 'Toạ độ không hợp lệ.'}, status=400)

    cache_key = (
        f'places:reverse:{latitude:.4f},{longitude:.4f}'
    )
    cached = cache.get(cache_key)
    if cached is not None:
        return JsonResponse(cached)

    goong_key = _goong_key()
    try:
        if goong_key:
            params = urlencode(
                {
                    'latlng': f'{latitude},{longitude}',
                    'api_key': goong_key,
                }
            )
            data = _fetch_json(f'{GOONG_BASE}/geocode?{params}')
            results = data.get('results') or []
            if not results:
                return JsonResponse(
                    {'error': 'Không tìm thấy địa chỉ cho vị trí này.'},
                    status=404,
                )
            first = results[0]
            location = (first.get('geometry') or {}).get('location') or {}
            payload = {
                'provider': 'goong',
                'result': {
                    'lat': location.get('lat', latitude),
                    'lng': location.get('lng', longitude),
                    'formatted_address': first.get('formatted_address', ''),
                },
            }
        else:
            _wait_for_nominatim()
            params = urlencode(
                {
                    'format': 'jsonv2',
                    'lat': latitude,
                    'lon': longitude,
                    'zoom': 18,
                    'accept-language': 'vi',
                }
            )
            data = _fetch_json(
                f'{NOMINATIM_BASE}/reverse?{params}', use_nominatim=True
            )
            if data.get('error'):
                return JsonResponse(
                    {'error': 'Không tìm thấy địa chỉ cho vị trí này.'},
                    status=404,
                )
            payload = {
                'provider': 'nominatim',
                'result': {
                    'lat': float(data.get('lat', latitude)),
                    'lng': float(data.get('lon', longitude)),
                    'formatted_address': data.get('display_name', ''),
                },
            }
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        return _upstream_error(error)

    cache.set(cache_key, payload, 60 * 60 * 24)
    return JsonResponse(payload)

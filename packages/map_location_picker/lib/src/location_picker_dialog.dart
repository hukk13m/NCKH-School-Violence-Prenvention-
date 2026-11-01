import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'config/map_config.dart';
import 'device_location_service.dart';
import 'geocoding/address_format.dart';
import 'geocoding/geocoding_service.dart';
import 'picked_location.dart';

/// Full map picker with search, reverse geocoding and GPS.
///
/// Pass [geocoder] / [deviceLocation] in tests to avoid real network and
/// platform calls. When omitted the dialog owns (and disposes) the defaults.
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({
    super.key,
    this.initial,
    this.geocoder,
    this.deviceLocation,
    this.apiBaseUrl = '',
    this.userAgentPackageName = 'school-violation-detector',
  });

  final PickedLocation? initial;
  final GeocodingService? geocoder;
  final DeviceLocationService? deviceLocation;

  /// Django base URL used by [BackendGeocoder].
  final String apiBaseUrl;

  final String userAgentPackageName;

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  static const LatLng _fallbackCenter = LatLng(10.7769, 106.7009);

  final TextEditingController _addressCtrl = TextEditingController();
  final FocusNode _addressFocus = FocusNode();

  MapLibreMapController? _mapCtrl;
  late final GeocodingService _geocoder;
  late final bool _ownsGeocoder;
  late final DeviceLocationService _deviceLocation;

  Timer? _reverseDebounce;
  Timer? _searchDebounce;
  Timer? _skipReverseTimer;
  int _reverseRequestId = 0;
  int _searchRequestId = 0;

  LatLng _center = _fallbackCenter;
  List<PlaceSuggestion> _suggestions = const [];

  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _isSearching = false;
  bool _isMapMoving = false;
  bool _isConfirming = false;
  bool _isSatellite = false;
  bool _userEdited = false;
  bool _skipNextReverse = false;
  bool _didInitialReverse = false;
  String? _error;
  String _lastKnownAddress = '';

  bool get _isBusy => _isGeocoding || _isSearching || _isConfirming;

  @override
  void initState() {
    super.initState();
    _ownsGeocoder = widget.geocoder == null;
    _geocoder =
        widget.geocoder ??
        (widget.apiBaseUrl.trim().isNotEmpty
            ? BackendGeocoder(baseUrl: widget.apiBaseUrl)
            : NominatimGeocoder());
    _deviceLocation = widget.deviceLocation ?? const DeviceLocationService();

    final initial = widget.initial;
    if (initial != null && initial.hasCoordinates) {
      _center = LatLng(initial.latitude!, initial.longitude!);
      _addressCtrl.text = initial.addressText ?? '';
      _lastKnownAddress = _addressCtrl.text;
    } else {
      _addressCtrl.text = 'TP. Hồ Chí Minh';
      _lastKnownAddress = _addressCtrl.text;
    }
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _searchDebounce?.cancel();
    _skipReverseTimer?.cancel();
    _addressCtrl.dispose();
    _addressFocus.dispose();
    _mapCtrl = null;
    if (_ownsGeocoder) _geocoder.dispose();
    super.dispose();
  }

  // ── Map events ────────────────────────────────────────────────
  void _handleCameraIdle() {
    _setMapMoving(false);

    if (_skipNextReverse) {
      _skipNextReverse = false;
      _skipReverseTimer?.cancel();
      return;
    }

    final target = _mapCtrl?.cameraPosition?.target;
    if (target == null) return;

    if (mounted) {
      setState(() {
        _center = target;
        _userEdited = false;
      });
    }
    _scheduleReverseGeocode(target);
  }

  void _setMapMoving(bool moving) {
    if (_isMapMoving == moving || !mounted) return;
    setState(() => _isMapMoving = moving);
  }

  // ── Reverse geocoding ─────────────────────────────────────────
  void _scheduleReverseGeocode(LatLng target) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(target);
    });
  }

  Future<void> _reverseGeocode(LatLng target) async {
    final requestId = ++_reverseRequestId;
    if (mounted) {
      setState(() {
        _isGeocoding = true;
        _error = null;
      });
    }

    try {
      final place = await _geocoder.reverse(target.latitude, target.longitude);
      if (!mounted || requestId != _reverseRequestId) return;

      if (place != null) {
        _lastKnownAddress = place.displayName;
        if (!_userEdited) _addressCtrl.text = place.displayName;
      } else if (!_userEdited && _addressCtrl.text.trim().isEmpty) {
        final label = _coordinateLabel(target);
        _addressCtrl.text = label;
        _lastKnownAddress = label;
      }
    } on GeocodingException catch (error) {
      if (!mounted || requestId != _reverseRequestId) return;
      _setError(error.message);
      _fillCoordinatesIfEmpty(target);
    } on TimeoutException {
      if (!mounted || requestId != _reverseRequestId) return;
      _setError('Lấy địa chỉ quá lâu. Kiểm tra kết nối mạng rồi thử lại.');
      _fillCoordinatesIfEmpty(target);
    } catch (error) {
      debugPrint('Reverse geocode failed: $error');
      if (!mounted || requestId != _reverseRequestId) return;
      _setError('Không lấy được địa chỉ từ vị trí đã chọn.');
      _fillCoordinatesIfEmpty(target);
    } finally {
      if (mounted && requestId == _reverseRequestId) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  void _fillCoordinatesIfEmpty(LatLng target) {
    if (_userEdited || _addressCtrl.text.trim().isNotEmpty) return;
    final label = _coordinateLabel(target);
    _addressCtrl.text = label;
    _lastKnownAddress = label;
  }

  // ── Search / forward geocoding ────────────────────────────────
  void _onAddressChanged(String value) {
    _userEdited = true;
    _reverseDebounce?.cancel();
    _searchDebounce?.cancel();
    if (_error != null) _setError(null);

    final query = value.trim();
    if (query.length < 3) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 650),
      () => _searchSuggestions(query),
    );
  }

  Future<void> _searchSuggestions(String query) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _geocoder.suggest(query);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = results;
        if (results.isEmpty) {
          _error = 'Không tìm thấy địa chỉ phù hợp.';
        }
      });
    } on GeocodingException catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      _setError(error.message);
    } on TimeoutException {
      if (!mounted || requestId != _searchRequestId) return;
      _setError('Tìm địa chỉ quá lâu. Kiểm tra kết nối mạng rồi thử lại.');
    } catch (error) {
      debugPrint('Address search failed: $error');
      if (!mounted || requestId != _searchRequestId) return;
      _setError('Không tìm kiếm được địa chỉ.');
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _onSearchSubmitted(String raw) async {
    _searchDebounce?.cancel();
    final text = raw.trim();
    if (text.isEmpty) return;

    final coordinates = parseCoordinateInput(text);
    if (coordinates != null) {
      final target = LatLng(coordinates.latitude, coordinates.longitude);
      _moveTo(target, address: _coordinateLabel(target));
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
      _error = null;
      _suggestions = const [];
    });

    try {
      final results = await _geocoder.suggest(text, limit: 1);
      if (!mounted || requestId != _searchRequestId) return;
      if (results.isEmpty) {
        _setError('Không tìm thấy địa chỉ "$text".');
        return;
      }
      await _resolveAndMove(results.first, requestId: requestId);
    } on GeocodingException catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      _setError(error.message);
    } on TimeoutException {
      if (!mounted || requestId != _searchRequestId) return;
      _setError('Tìm địa chỉ quá lâu. Kiểm tra kết nối mạng rồi thử lại.');
    } catch (error) {
      debugPrint('Address submit failed: $error');
      if (!mounted || requestId != _searchRequestId) return;
      _setError('Không tìm kiếm được địa chỉ.');
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _resolveAndMove(
    PlaceSuggestion suggestion, {
    int? requestId,
  }) async {
    final place = await _geocoder.resolve(suggestion);
    if (!mounted) return;
    if (requestId != null && requestId != _searchRequestId) return;
    if (place == null) {
      _setError('Không lấy được toạ độ của địa chỉ đã chọn.');
      return;
    }
    _moveTo(
      LatLng(place.latitude, place.longitude),
      address: place.displayName,
    );
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _addressFocus.unfocus();
    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
      _error = null;
      _suggestions = const [];
    });

    try {
      await _resolveAndMove(suggestion, requestId: requestId);
    } on GeocodingException catch (error) {
      if (mounted && requestId == _searchRequestId) _setError(error.message);
    } on TimeoutException {
      if (mounted && requestId == _searchRequestId) {
        _setError('Lấy toạ độ địa chỉ quá lâu. Vui lòng thử lại.');
      }
    } catch (error) {
      debugPrint('Resolve suggestion failed: $error');
      if (mounted && requestId == _searchRequestId) {
        _setError('Không lấy được toạ độ của địa chỉ đã chọn.');
      }
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _moveTo(LatLng target, {String? address, bool skipReverse = true}) {
    _addressFocus.unfocus();
    _reverseDebounce?.cancel();
    _searchDebounce?.cancel();

    if (skipReverse) {
      _skipNextReverse = true;
      _skipReverseTimer?.cancel();
      _skipReverseTimer = Timer(const Duration(seconds: 3), () {
        _skipNextReverse = false;
      });
    } else {
      _skipNextReverse = false;
      _skipReverseTimer?.cancel();
    }

    if (mounted) {
      setState(() {
        _center = target;
        _userEdited = false;
        _suggestions = const [];
        _error = null;
        if (address != null) {
          _addressCtrl.text = address;
          _lastKnownAddress = address;
        }
      });
    }

    final controller = _mapCtrl;
    if (controller != null) {
      unawaited(
        controller.animateCamera(CameraUpdate.newLatLngZoom(target, 17)),
      );
    }
    if (!skipReverse) _scheduleReverseGeocode(target);
  }

  // ── GPS ───────────────────────────────────────────────────────
  Future<void> _useCurrentLocation() async {
    _addressFocus.unfocus();
    setState(() {
      _isLocating = true;
      _error = null;
    });

    try {
      final target = await _deviceLocation.currentPosition();
      if (!mounted) return;
      _moveTo(target, skipReverse: false);
    } on LocationFailure catch (error) {
      if (mounted) _setError(error.message);
    } catch (error) {
      debugPrint('GPS failed: $error');
      if (mounted) _setError('Không thể lấy vị trí GPS.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Confirm ───────────────────────────────────────────────────
  Future<void> _confirm() async {
    if (_isConfirming) return;
    _addressFocus.unfocus();

    final typed = _addressCtrl.text.trim();
    var target = _center;
    var address = typed;

    if (_userEdited && typed.isNotEmpty) {
      final coordinates = parseCoordinateInput(typed);
      if (coordinates != null) {
        target = LatLng(coordinates.latitude, coordinates.longitude);
        address = _coordinateLabel(target);
      } else {
        setState(() {
          _isConfirming = true;
          _error = null;
        });
        try {
          final results = await _geocoder.suggest(typed, limit: 1);
          if (!mounted) return;
          if (results.isEmpty) {
            _setError(
              'Không tìm thấy địa chỉ "$typed". '
              'Hãy chọn một gợi ý hoặc di chuyển bản đồ.',
            );
            return;
          }

          final place = await _geocoder.resolve(results.first);
          if (!mounted) return;
          if (place == null) {
            _setError('Không xác minh được toạ độ của địa chỉ đã nhập.');
            return;
          }

          target = LatLng(place.latitude, place.longitude);
          address = place.displayName;
          _addressCtrl.text = address;
          _lastKnownAddress = address;
          _userEdited = false;
        } on GeocodingException catch (error) {
          if (mounted) _setError(error.message);
          return;
        } on TimeoutException {
          if (mounted) {
            _setError('Xác minh địa chỉ quá lâu. Vui lòng thử lại.');
          }
          return;
        } catch (error) {
          debugPrint('Confirm geocode failed: $error');
          if (mounted) _setError('Không xác minh được địa chỉ đã nhập.');
          return;
        } finally {
          if (mounted) setState(() => _isConfirming = false);
        }
      }
    }

    if (!mounted) return;
    if (address.isEmpty) address = _lastKnownAddress;
    if (address.isEmpty) address = _coordinateLabel(target);

    Navigator.pop(
      context,
      PickedLocation(
        addressText: address,
        latitude: target.latitude,
        longitude: target.longitude,
      ),
    );
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _toggleStyle() async {
    if (!MapLocationPickerConfig.usesGoong) return;
    final next = !_isSatellite;
    setState(() => _isSatellite = next);
    try {
      await _mapCtrl?.setStyle(
        next
            ? MapLocationPickerConfig.satelliteStyle
            : MapLocationPickerConfig.normalStyle,
      );
    } catch (error) {
      debugPrint('Change map style failed: $error');
      if (mounted) {
        _setError('Không đổi được kiểu bản đồ.');
        setState(() => _isSatellite = !next);
      }
    }
  }

  String _coordinateLabel(LatLng point) =>
      'Tọa độ: ${point.latitude.toStringAsFixed(6)}, '
      '${point.longitude.toStringAsFixed(6)}';

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 640;
    final topInset = compact ? media.padding.top : 24.0;
    final bottomInset = compact ? media.viewInsets.bottom : 24.0;
    final width = compact ? media.size.width : 680.0;
    final height = compact
        ? media.size.height - topInset - bottomInset
        : (media.size.height - 48).clamp(360.0, 680.0).toDouble();

    return Dialog(
      insetPadding: compact
          ? EdgeInsets.only(top: topInset, bottom: bottomInset)
          : const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: compact
          ? const RoundedRectangleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Stack(
                children: [
                  MapLibreMap(
                    styleString: _isSatellite
                        ? MapLocationPickerConfig.satelliteStyle
                        : MapLocationPickerConfig.normalStyle,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: widget.initial?.hasCoordinates == true ? 17 : 14,
                    ),
                    onMapCreated: (controller) => _mapCtrl = controller,
                    onStyleLoadedCallback: () {
                      if (_didInitialReverse) return;
                      _didInitialReverse = true;
                      _scheduleReverseGeocode(_center);
                    },
                    onCameraMove: (_) => _setMapMoving(true),
                    onCameraIdle: _handleCameraIdle,
                    minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    compassEnabled: false,
                    attributionButtonPosition:
                        AttributionButtonPosition.bottomRight,
                  ),
                  const IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(
                          Icons.location_pin,
                          color: Color(0xFFCF3C3C),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _buildAddressCard(context),
                  ),
                ],
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: const Color(0xFF0D4D8A),
      child: Row(
        children: [
          const Icon(Icons.map_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Bản đồ chọn vị trí',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          if (MapLocationPickerConfig.usesGoong)
            IconButton(
              tooltip: _isSatellite ? 'Bản đồ thường' : 'Bản đồ vệ tinh',
              icon: Icon(
                _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                color: Colors.white,
              ),
              onPressed: _toggleStyle,
            ),
          IconButton(
            tooltip: 'Đóng',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final status = _isBusy
        ? 'Đang xử lý địa chỉ...'
        : _isMapMoving
        ? 'Đang di chuyển bản đồ...'
        : 'Vị trí đã chọn';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isBusy ? Icons.sync : Icons.location_on,
                  size: 18,
                  color: const Color(0xFF0B6EDB),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF58708F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            TextField(
              controller: _addressCtrl,
              focusNode: _addressFocus,
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.search,
              onChanged: _onAddressChanged,
              onSubmitted: _onSearchSubmitted,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0A2F5D),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Nhập địa chỉ hoặc chọn trên bản đồ...',
                border: InputBorder.none,
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Tìm địa chỉ',
                        icon: const Icon(Icons.search_rounded, size: 20),
                        onPressed: () => _onSearchSubmitted(_addressCtrl.text),
                      ),
              ),
            ),
            if (_isGeocoding)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCF3C3C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_suggestions.isNotEmpty) ...[
              const Divider(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 210),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: Color(0xFF0B6EDB),
                      ),
                      title: Text(
                        place.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF0A2F5D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _selectSuggestion(place),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3ECFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 20),
              label: const Text('Vị trí GPS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0B6EDB),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isConfirming ? null : _confirm,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: const Text('Xác nhận'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6EDB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

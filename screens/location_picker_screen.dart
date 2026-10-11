import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/picked_location.dart';

class LocationPickerScreen extends StatefulWidget {
  final PickedLocation? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _addressCtrl = TextEditingController();
  final MapController _mapCtrl = MapController();

  LatLng _center = const LatLng(10.7769, 106.7009); // TP.HCM mặc định
  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _isMapMoving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _addressCtrl.text = widget.initial!.addressText ?? '';
      if (widget.initial!.hasCoordinates) {
        _center = LatLng(widget.initial!.latitude!, widget.initial!.longitude!);
      }
    } else {
      // Tự động lấy vị trí hiện tại lần đầu
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnack('Vui lòng bật GPS trên thiết bị.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showSnack('Ứng dụng chưa được cấp quyền vị trí.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = ll);
      _mapCtrl.move(ll, 17);
      await _reverseGeocode(ll);
    } catch (e) {
      _showSnack('Không lấy được vị trí: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng ll) async {
    setState(() => _isGeocoding = true);
    String? addr;

    // 1️⃣ Thử native geocoding (Google Geocoder trên Android)
    try {
      final placemarks =
      await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.street ?? '').isNotEmpty) p.street!,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
        ];
        if (parts.isNotEmpty) addr = parts.join(', ');
      }
    } catch (e) {
      debugPrint('Native geocode fail: $e');   // ← log ra, không nuốt
    }

    // 2️⃣ Fallback: Nominatim OSM (miễn phí, không cần API key)
    if (addr == null || addr.isEmpty) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
              '?format=json&lat=${ll.latitude}&lon=${ll.longitude}&accept-language=vi',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'school_violence_app/1.0',
        });
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final display = data['display_name']?.toString();
          if (display != null && display.isNotEmpty) addr = display;
        }
      } catch (e) {
        debugPrint('Nominatim fail: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      if (addr != null && addr.isNotEmpty) {
        _addressCtrl.text = addr;
      } else {
        // Cùng lắm thì hiển thị toạ độ để user biết đã có vị trí
        _addressCtrl.text =
        '${ll.latitude.toStringAsFixed(6)}, ${ll.longitude.toStringAsFixed(6)}';
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirm() {
    final text = _addressCtrl.text.trim();

    // Nếu address trống → dùng toạ độ làm text
    final finalAddress = text.isEmpty
        ? '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}'
        : text;

    final result = PickedLocation(
      addressText: finalAddress,
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() => _isMapMoving = true);
                } else if (event is MapEventMoveEnd ||
                    event is MapEventFlingAnimationEnd) {
                  final c = _mapCtrl.camera.center;
                  setState(() {
                    _isMapMoving = false;
                    _center = c;
                  });
                  _reverseGeocode(c);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.school_violence_app',
              ),
            ],
          ),

          // PIN cố định giữa màn hình (kiểu Zalo)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 48,
                ),
              ),
            ),
          ),

          // Card địa chỉ trên đầu
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isMapMoving ? Icons.sync : Icons.location_on,
                          size: 18,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isMapMoving
                              ? 'Đang di chuyển bản đồ...'
                              : 'Vị trí đã chọn',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _addressCtrl,
                      minLines: 1,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Địa chỉ',
                        border: InputBorder.none,
                      ),
                    ),
                    if (_isGeocoding)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2 nút bên dưới
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.indigo,
                      ),
                    )
                        : const Icon(Icons.my_location),
                    label: const Text('Vị trí hiện tại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }
}
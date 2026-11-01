import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/sos_settings_store.dart';

class SosOfflineScreen extends StatefulWidget {
  const SosOfflineScreen({super.key});

  @override
  State<SosOfflineScreen> createState() => _SosOfflineScreenState();
}

class _SosOfflineScreenState extends State<SosOfflineScreen> {
  final SosSettingsStore _store = SosSettingsStore();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    _phoneController.text = settings.contactPhone;
    _messageController.text = settings.emergencyMessage;
    setState(() {
      _enabled = settings.offlineEnabled;
      _loading = false;
    });
  }

  Future<void> _save({bool showFeedback = true}) async {
    await _store.save(
      SosSettings(
        offlineEnabled: _enabled,
        contactPhone: _phoneController.text,
        emergencyMessage: _messageController.text,
      ),
    );
    if (!mounted || !showFeedback) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cấu hình chia sẻ ngoại tuyến.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startSharing() async {
    if (!_enabled || _saving) return;
    setState(() => _saving = true);
    await _save(showFeedback: false);
    if (!mounted) return;

    final phone = _phoneController.text.trim();
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    if (isOffline && phone.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: phone);
      final opened = await launchUrl(uri);
      if (!mounted) return;
      if (!opened) {
        _showMessage('Không thể mở trình gọi điện trên thiết bị này.');
      }
    } else if (phone.isEmpty) {
      _showMessage(
        'Đã bật chế độ ngoại tuyến. Bạn có thể bổ sung số điện thoại sau.',
      );
    } else {
      _showMessage(
        'Đã bật chế độ ngoại tuyến. Khi mất mạng, ứng dụng sẽ gọi số $phone.',
      );
    }

    if (mounted) setState(() => _saving = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3B7A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chia sẻ ngoại tuyến',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 16),
                    _buildToggleCard(),
                    const SizedBox(height: 18),
                    const Text(
                      'THÔNG TIN KHẨN CẤP',
                      style: TextStyle(
                        color: Color(0xFF0A2F5D),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Các trường này để trống cho đến khi nhà trường cung cấp '
                      'đầu mối liên hệ.',
                      style: TextStyle(
                        color: Color(0xFF718CB0),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => _save(showFeedback: false),
                      decoration: _inputDecoration(
                        label: 'Số điện thoại liên lạc khẩn cấp',
                        hint: 'Chưa có số điện thoại',
                        icon: Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (_) => _save(showFeedback: false),
                      decoration: _inputDecoration(
                        label: 'Lời nhắn khẩn cấp',
                        hint: 'Chưa có lời nhắn',
                        icon: Icons.message_rounded,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildNoticeCard(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _enabled && !_saving ? _startSharing : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFCF3C3C),
                          disabledBackgroundColor: const Color(0xFFD7DEE9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_location_rounded),
                        label: const Text(
                          'Bắt đầu chia sẻ khẩn cấp',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6EDB), Color(0xFF0B3B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3B7A).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.share_location_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Chia sẻ vị trí và bằng chứng ngay cả khi không có kết nối mạng.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EEFC)),
      ),
      child: SwitchListTile.adaptive(
        value: _enabled,
        activeTrackColor: const Color(0xFF0B6EDB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: const Text(
          'Bật chia sẻ ngoại tuyến',
          style: TextStyle(
            color: Color(0xFF0A2F5D),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Tự động gọi và lưu bằng chứng khi mất WiFi/dữ liệu',
          style: TextStyle(color: Color(0xFF718CB0), fontSize: 11.5),
        ),
        onChanged: (value) async {
          setState(() => _enabled = value);
          await _save(showFeedback: false);
        },
      ),
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5E6FB)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF0B6EDB), size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Khi không có WiFi/dữ liệu, hệ thống sẽ cố gắng gọi trực tiếp '
              'đến đầu mối liên hệ khẩn cấp. Khi có kết nối trở lại, báo cáo '
              'và vị trí sẽ được tự động gửi đến máy chủ.',
              style: TextStyle(
                color: Color(0xFF2B5D9B),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: alignLabelWithHint ? 54 : 0),
        child: Icon(icon, color: const Color(0xFF0B6EDB), size: 20),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1ECFA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1ECFA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0B6EDB), width: 1.4),
      ),
    );
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/sos_service.dart';
import '../data/sos_settings_store.dart';
import '../services/shake_detector.dart';
import '../services/sos_alarm_service.dart';
import 'sos_offline_screen.dart';
import 'sos_permission_sheet.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key, required this.userId, required this.userName});

  final String userId;
  final String userName;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SosService _sosService = SosService();
  final SosAlarmService _alarmService = SosAlarmService();
  final SosSettingsStore _settingsStore = SosSettingsStore();

  late final ShakeDetector _shakeDetector;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SosSettings _settings = const SosSettings();
  bool _isOnline = true;
  bool _isSending = false;
  bool _alarmActive = false;
  int _countdownRemaining = 0;
  Timer? _countdownTimer;
  String? _statusMessage;
  Color _statusColor = const Color(0xFF0B6EDB);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeDetector = ShakeDetector(onShake: _handleShake);
    _loadSettings();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    _shakeDetector.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushQueue());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeDetector.dispose();
    _connectivitySubscription?.cancel();
    _alarmService.dispose();
    _sosService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsStore.load();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() => _isOnline = !result.contains(ConnectivityResult.none));
      }
    } catch (_) {
      // Giữ trạng thái mặc định nếu plugin không khả dụng.
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = !results.contains(ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _isOnline = online);
    if (online) _flushQueue();
  }

  Future<void> _flushQueue() async {
    if (!_isOnline) return;
    try {
      final sent = await _sosService.flushPendingReports();
      if (sent > 0 && mounted) {
        _showMessage('Đã gửi lại $sent báo cáo SOS đang chờ.');
      }
    } catch (_) {
      // Lần sau kết nối ổn định sẽ thử lại.
    }
  }

  void _handleShake() {
    if (_isSending || _alarmActive || _countdownRemaining > 0) return;
    _triggerSos();
  }

  Future<void> _triggerSos() async {
    if (_isSending || _alarmActive || _countdownRemaining > 0) return;

    setState(() {
      _countdownRemaining = 5;
      _statusMessage = 'SOS sẽ kích hoạt sau 5 giây. Bấm nút đỏ để hủy.';
      _statusColor = const Color(0xFFB7791F);
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownRemaining <= 1) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _countdownRemaining = 0);
        _activateSos();
      } else {
        setState(() => _countdownRemaining--);
      }
    });
  }

  Future<void> _activateSos() async {
    if (_isSending || _alarmActive) return;

    setState(() {
      _isSending = true;
      _alarmActive = true;
      _statusMessage = 'Đang phát tín hiệu SOS và gửi vị trí...';
      _statusColor = const Color(0xFF0B6EDB);
    });

    HapticFeedback.heavyImpact();
    await _alarmService.start();
    _showMessage('Đã kích hoạt SOS khẩn cấp.');

    await _sendSosReport();
  }

  Future<void> _cancelCountdown() async {
    if (_countdownRemaining <= 0) return;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    await _alarmService.stop();
    if (!mounted) return;
    setState(() {
      _countdownRemaining = 0;
      _alarmActive = false;
      _isSending = false;
      _statusMessage = 'Đã hủy gửi SOS.';
      _statusColor = const Color(0xFF53709F);
    });
  }

  Future<void> _sendSosReport() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);
      final phone = _settings.contactPhone.trim();
      if (isOffline && _settings.offlineEnabled && phone.isNotEmpty) {
        await launchUrl(Uri(scheme: 'tel', path: phone));
      }

      final result = await _sosService.sendSos(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _statusMessage = result.message;
        _statusColor = result.success
            ? const Color(0xFF1AA06A)
            : const Color(0xFFB7791F);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _statusMessage =
            'Không thể gửi báo cáo. Vui lòng kiểm tra kết nối và thử lại.';
        _statusColor = const Color(0xFFCF3C3C);
      });
    }
  }

  Future<void> _stopAlarm() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    await _alarmService.stop();
    if (!mounted) return;
    setState(() {
      _countdownRemaining = 0;
      _alarmActive = false;
      _isSending = false;
      _statusMessage = 'Đã dừng tín hiệu SOS.';
      _statusColor = const Color(0xFF53709F);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openOfflineSettings() async {
    Navigator.of(context).pop();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SosOfflineScreen()));
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F9FF),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3B7A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Tùy chọn SOS',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'SOS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.8),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? const Color(0xFF1AA06A).withValues(alpha: 0.22)
                      : const Color(0xFFFFB020).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 13,
                      color: _isOnline
                          ? const Color(0xFF7CF0C0)
                          : const Color(0xFFFFD28A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isOnline
                            ? const Color(0xFFB8FFE0)
                            : const Color(0xFFFFE1B0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          child: Column(
            children: [
              _buildShieldVisual(),
              const SizedBox(height: 20),
              const Text(
                'Nhận trợ giúp qua tính năng SOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0A2F5D),
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Trong trường hợp khẩn cấp, hãy lắc điện thoại 5 lần',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF53709F),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              ScaleTransition(scale: _pulseAnimation, child: _buildSosButton()),
              const SizedBox(height: 16),
              Text(
                _countdownRemaining > 0
                    ? 'BẤM NÚT ĐỎ ĐỂ HỦY'
                    : 'ẤN NÚT TRONG TRƯỜNG HỢP KHẨN CẤP',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFCF3C3C),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              if (_alarmActive) ...[
                const SizedBox(height: 20),
                _buildAlarmCard(),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                _buildStatusCard(),
              ],
              const SizedBox(height: 22),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: Color(0xFF8AA5C7),
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Vị trí hiện tại sẽ được gửi kèm báo cáo SOS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8AA5C7),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShieldVisual() {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B6EDB).withValues(alpha: 0.06),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B6EDB).withValues(alpha: 0.11),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0B6EDB),
            ),
            child: const Icon(
              Icons.vibration_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosButton() {
    final isCounting = _countdownRemaining > 0;
    return Semantics(
      button: true,
      label: isCounting ? 'Hủy SOS' : 'Nút SOS khẩn cấp',
      child: GestureDetector(
        onTap: _isSending
            ? null
            : (isCounting ? _cancelCountdown : _triggerSos),
        child: Container(
          width: 198,
          height: 198,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFF25B5B), Color(0xFFCF3C3C)],
              center: Alignment(-0.25, -0.3),
              radius: 1.05,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCF3C3C).withValues(alpha: 0.32),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 0,
                spreadRadius: 7,
              ),
            ],
          ),
          child: Center(
            child: _isSending
                ? const SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  )
                : isCounting
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_countdownRemaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 82,
                          fontWeight: FontWeight.w900,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'BẤM ĐỂ HỦY',
                        style: TextStyle(
                          color: Color(0xFFFFE3E3),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'KHẨN CẤP',
                        style: TextStyle(
                          color: Color(0xFFFFE3E3),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCFCF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFFCF3C3C)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Đang phát tín hiệu SOS...',
              style: TextStyle(
                color: Color(0xFF9B2C2C),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _stopAlarm,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCF3C3C),
              minimumSize: const Size(50, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Dừng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _statusColor == const Color(0xFF1AA06A)
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: _statusColor,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _statusColor,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.84,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 18, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFCF3C3C), Color(0xFF9B2C2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFFCF3C3C),
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Tùy chọn SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Thiết lập bảo vệ của bạn',
                    style: TextStyle(color: Color(0xFFFFE3E3), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _DrawerOption(
              icon: Icons.shield_rounded,
              iconColor: const Color(0xFFCF3C3C),
              title: 'Chia sẻ khẩn cấp',
              subtitle: 'Quyền truy cập của hệ thống',
              onTap: () {
                Navigator.of(context).pop();
                showSosPermissionSheet(context);
              },
            ),
            _DrawerOption(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFF0B6EDB),
              title: 'Chia sẻ ngoại tuyến',
              subtitle: 'Khi không có kết nối mạng',
              onTap: _openOfflineSettings,
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Text(
                'Hệ thống sẽ gửi vị trí và thông tin khẩn cấp đến trung tâm '
                'hỗ trợ ngay khi bạn kích hoạt SOS.',
                style: TextStyle(
                  color: Color(0xFF8AA5C7),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerOption extends StatelessWidget {
  const _DrawerOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF0A2F5D),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF718CB0),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8AA5C7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

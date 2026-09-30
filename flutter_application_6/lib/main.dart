import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:async';

import 'shake_detector.dart';

void main() {
  runApp(const SOSApp());
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Violation Detector',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Snow White
        primaryColor: const Color(0xFFD32F2F), // Ruby Red
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- SCREEN 1: HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    // Shake detection logic
    _shakeDetector = ShakeDetector(
      onShakeThresholdReached: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SOSMainScreen()),
        );
      },
      shakeThresholdGravity: 1.5,
      shakeCountResetTimeMs: 3000,
      shakeCountThreshold: 5,
    );
    _shakeDetector.startListening();
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'School Violation Detector',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 30),
            onSelected: (value) {
              if (value == 'logout') {
                // Handle logout
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'account', child: Text('Tài khoản')),
              const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 100, color: Color(0xFFD32F2F)),
            SizedBox(height: 20),
            Text(
              'Chúng tôi sẽ luôn đồng hành cùng bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12.0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.home_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.bar_chart_outlined), onPressed: () {}),
              const SizedBox(width: 48), // Space for FAB
              IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
              IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SOSIntroScreen()),
            );
          },
          backgroundColor: const Color(0xFFD32F2F),
          shape: const CircleBorder(),
          elevation: 10,
          child: const Text(
            'SOS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// --- SCREEN 2: SOS INTRO / PERMISSIONS ---
class SOSIntroScreen extends StatelessWidget {
  const SOSIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOS',
                style: TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'SOS cần có những quyền sau:',
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildPermissionItem(Icons.contacts, 'Danh bạ', 'Dùng để truy cập và sửa danh bạ của bạn'),
              _buildPermissionItem(Icons.sms, 'Tin nhắn SMS', 'Dùng để gửi và nhận tin nhắn'),
              _buildPermissionItem(Icons.location_on, 'Vị trí', 'Dùng để chia sẻ vị trí của bạn trong tin nhắn khẩn cấp'),
              _buildPermissionItem(Icons.mic, 'Micrô', 'Dùng để ghi âm cho tin nhắn khẩn cấp'),
              _buildPermissionItem(Icons.notifications, 'Thông báo', 'Dùng để hiển thị các cập nhật về vị trí và thông tin khẩn cấp của bạn'),
              _buildPermissionItem(Icons.camera_alt, 'Máy ảnh', 'Dùng để chụp ảnh và chia sẻ trong tin nhắn khẩn cấp'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SOSMainScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleIcons.roundedRect(25),
                  ),
                  child: const Text('Tiếp tục', style: TextStyle(fontSize: 18, color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87, size: 30),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SCREEN 3: SOS MAIN SCREEN ---
class SOSMainScreen extends StatefulWidget {
  const SOSMainScreen({super.key});

  @override
  State<SOSMainScreen> createState() => _SOSMainScreenState();
}

class _SOSMainScreenState extends State<SOSMainScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  int _countdown = 5;
  bool _isCounting = false;
  Timer? _timer;

  // Permission states for the bottom sheet
  bool _locationEnabled = true;
  bool _cameraEnabled = true;
  bool _micEnabled = true;
  bool _contactsEnabled = true;
  bool _smsEnabled = true;

  // Animation controllers for ripple effect
  late AnimationController _rippleController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  void _startSOSSequence() {
    if (_isCounting || _isAlarmPlaying) return;

    setState(() {
      _isCounting = true;
      _countdown = 5;
    });

    _rippleController.repeat(); // Bắt đầu tỏa sóng ngay khi đếm ngược

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _activateAlarm();
      }
    });
  }

  void _activateAlarm() {
    _startAlarm();
    _rippleController.repeat();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tín hiệu SOS đã được gửi!', textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    setState(() {
      _isCounting = false;
    });
  }

  void _stopSOS() {
    _audioPlayer.stop();
    _rippleController.stop();
    _timer?.cancel();
    setState(() {
      _isAlarmPlaying = false;
      _isCounting = false;
      _countdown = 5;
    });
  }

  void _startAlarm() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/soundreality-sos-signal-137144.mp3'));
      setState(() => _isAlarmPlaying = true);
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _rippleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'SOS',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFD32F2F)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Tùy chọn SOS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Thiết lập bảo vệ của bạn', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF333333)),
              title: const Text('Chia sẻ khẩn cấp', style: TextStyle(color: Color(0xFF333333))),
              onTap: () {
                Navigator.pop(context);
                _showPermissionSwitches(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.offline_bolt, color: Colors.orange),
              title: const Text('Chia sẻ ngoại tuyến', style: TextStyle(color: Color(0xFF333333))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OfflineSharingScreen()));
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nhận trợ giúp qua tính năng SOS',
              style: TextStyle(color: Color(0xFF333333), fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Shake Animation
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _shakeController.value * 0.2,
                  child: const Icon(Icons.vibration, size: 40, color: Colors.grey),
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Trong trường hợp khẩn cấp, hãy lắc điện thoại 5 lần',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                if (_isAlarmPlaying) {
                  _stopSOS();
                } else {
                  _startSOSSequence();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple Effect
                  if (_isAlarmPlaying || _isCounting)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return Container(
                          width: 250 + (100 * _rippleController.value),
                          height: 250 + (100 * _rippleController.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD32F2F).withAlpha(( (1 - _rippleController.value) * 255).toInt()),
                          ),
                        );
                      },
                    ),
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withAlpha(128),
                          spreadRadius: 20,
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isCounting
                            ? '$_countdown'
                            : (_isAlarmPlaying ? 'DỪNG' : 'SOS'),
                        style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'ẤN NÚT TRONG TRƯỜNG HỢP KHẨN CẤP',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }



  void _showPermissionSwitches(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QUYỀN TRUY CẬP HỆ THỐNG', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildSwitchTile('Vị trí (Location)', 'Để gửi tọa độ khi gặp nạn', _locationEnabled, (val) {
                    setModalState(() => _locationEnabled = val);
                    setState(() {});
                  }),
                  _buildSwitchTile('Máy ảnh (Camera)', 'Để chụp ảnh hiện trường', _cameraEnabled, (val) {
                    setModalState(() => _cameraEnabled = val);
                    setState(() {});
                  }),
                  _buildSwitchTile('Microphone', 'Để ghi âm môi trường xung quanh', _micEnabled, (val) {
                    setModalState(() => _micEnabled = val);
                    setState(() {});
                  }),
                  _buildSwitchTile('Danh bạ (Contacts)', 'Để liên lạc người thân', _contactsEnabled, (val) {
                    setModalState(() => _contactsEnabled = val);
                    setState(() {});
                  }),
                  _buildSwitchTile('SMS', 'Để gửi tin nhắn khẩn cấp tự động', _smsEnabled, (val) {
                    setModalState(() => _smsEnabled = val);
                    setState(() {});
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: Colors.blue,
      ),
    );
  }
}

// --- SCREEN 4: OFFLINE SHARING SCREEN ---
class OfflineSharingScreen extends StatefulWidget {
  const OfflineSharingScreen({super.key});

  @override
  State<OfflineSharingScreen> createState() => _OfflineSharingScreenState();
}

class _OfflineSharingScreenState extends State<OfflineSharingScreen> {
  bool _isOfflineSharingEnabled = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Snow White
      appBar: AppBar(
        title: const Text('Chia sẻ ngoại tuyến', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustration/Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFEEEEEE),
                          child: Icon(Icons.person, color: Colors.grey, size: 40),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.location_on, color: Color(0xFFD32F2F)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.mic, color: Color(0xFFD32F2F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Khi không có kết nối Wifi/Dữ liệu di động, hệ thống sẽ tự động thực hiện cuộc gọi trực tiếp đến tổng đài phòng CTSV.\n\n'
                          'Khi có kết nối trở lại, các bằng chứng hình ảnh, âm thanh và vị trí sẽ được gửi lập tức qua thông báo khẩn cấp.',
                      style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Enable Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withAlpha(51)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bật chia sẻ ngoại tuyến', style: TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isOfflineSharingEnabled,
                      onChanged: (val) => setState(() => _isOfflineSharingEnabled = val),
                      activeThumbColor: Colors.blue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Fields (Blurred/Dimmed if disabled)
              Opacity(
                opacity: _isOfflineSharingEnabled ? 1.0 : 0.4,
                child: AbsorbPointer(
                  absorbing: !_isOfflineSharingEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('THÔNG TIN KHẨN CẤP', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại liên lạc khẩn cấp',
                        hint: 'Nhập số điện thoại...',
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _messageController,
                        label: 'Lời nhắn khẩn cấp',
                        hint: 'Ví dụ: Tôi đang gặp nguy hiểm tại...',
                        icon: Icons.message,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isOfflineSharingEnabled ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text('Bắt đầu chia sẻ khẩn cấp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF333333)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class RoundedRectangleIcons {
  static OutlinedBorder roundedRect(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
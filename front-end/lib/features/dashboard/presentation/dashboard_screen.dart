import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../auth/domain/auth_models.dart';
import '../data/case_service.dart';
import 'web_utils/web_utils.dart';
import 'widgets/account_profile_dialog.dart';
import '../../../core/localization/app_language.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int? _hoveredIndex;

  final CaseService _caseService = CaseService();
  final List<UploadedFile> _uploadedFiles = [];
  List<CaseModel> _historyCases = [];
  bool _isLoadingHistory = false;
  bool _isSubmitting = false;

  final TextEditingController _reportController = TextEditingController(
    text: '',
  );
  final TextEditingController _locationController = TextEditingController(
    text: 'Phòng 302, Tòa A',
  );

  // User Profile State
  String _userFullName = 'Anh Ly';
  String _userEmail = 'anh.ly086@university.edu';
  String _userIdCode = 'anh.ly086';
  String _userDepartment = 'Faculty of Information Systems';
  String _userRole = 'Sinh viên';

  bool _isVietnamese = true;
  final bool _hasNotification = true;
  bool _isLoggedIn = true;

  // --- Speech-to-Text (Voice to Text directly inside TextField) ---
  late stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isRecordingAudio = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // GlobalKeys for header popup positioning
  final GlobalKey _langKey = GlobalKey();
  final GlobalKey _notifKey = GlobalKey();

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) _fetchHistory();
    if (index == 1) _fetchCurrentLocation();
  }

  List<_SidebarItem> get _items => [
    _SidebarItem(
      title: _isVietnamese ? 'Báo cáo vi phạm' : 'Report Incident',
      icon: Icons.report_problem_outlined,
      subtitle: _isVietnamese ? 'Gửi thông tin mới' : 'Submit new report',
    ),
    _SidebarItem(
      title: _isVietnamese ? 'SOS Khẩn cấp' : 'Emergency SOS',
      icon: Icons.sos_outlined,
      subtitle: _isVietnamese ? 'Cấp cứu / Khẩn cấp' : 'Direct emergency beacon',
    ),
    _SidebarItem(
      title: _isVietnamese ? 'Xem báo cáo cũ' : 'Report History',
      icon: Icons.history_edu_outlined,
      subtitle: _isVietnamese ? 'Lịch sử đã gửi' : 'My submitted reports',
    ),
    _SidebarItem(
      title: _isVietnamese ? 'Chat với Chuyên viên' : 'Consultation & Chat',
      icon: Icons.chat_bubble_outline_rounded,
      subtitle: _isVietnamese ? 'Tư vấn & Hỗ trợ' : 'Advice & mental health',
    ),
  ];

  bool _initializedUser = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedUser) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is AuthSession) {
        setState(() {
          _userFullName = args.fullName;
          _userEmail = args.email;
          _userIdCode = args.userId;
          _userDepartment = args.department ?? 'Khoa Công nghệ Thông tin';
          _userRole = args.role == AuthRole.teacher ? 'Giảng viên' : 'Sinh viên';
        });
        _fetchHistory();
      }
      _initializedUser = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _isVietnamese = AppLanguage.instance.isVietnamese;
    AppLanguage.instance.localeNotifier.addListener(_onLocaleChanged);
    _speechToText = stt.SpeechToText();
    _initSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchHistory();
    _fetchCurrentLocation();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final cases = await _caseService.fetchCases(userId: _userEmail, role: 'student');
      if (mounted) {
        setState(() {
          _historyCases = cases;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (_) {
          if (mounted) {
            setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') &&
              mounted &&
              _isListening) {
            setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
      );
      setState(() {});
    } catch (_) {
      _speechEnabled = false;
    }
  }

  void _onLocaleChanged() {
    if (mounted) {
      setState(() {
        _isVietnamese = AppLanguage.instance.isVietnamese;
      });
    }
  }

  @override
  void dispose() {
    AppLanguage.instance.localeNotifier.removeListener(_onLocaleChanged);
    _reportController.dispose();
    _locationController.dispose();
    _pulseController.dispose();
    if (_isListening) _speechToText.stop();
    super.dispose();
  }

  // Speech-to-Text: Converts Voice directly into TextField Text
  Future<void> _toggleSTT() async {
    if (!_speechEnabled) {
      _showErrorSnack(
        'Trình duyệt không hỗ trợ Nhận dạng giọng nói. Hãy dùng Google Chrome hoặc Microsoft Edge.',
      );
      return;
    }
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      _pulseController.stop();
      return;
    }

    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    await _speechToText.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _isVietnamese ? 'vi-VN' : 'en-US',
        partialResults: false,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
      ),
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords.trim();
        if (result.finalResult && recognized.isNotEmpty) {
          final current = _reportController.text.trim();
          final next = current.isEmpty ? recognized : '$current $recognized';
          _reportController.text = next;
          _reportController.selection = TextSelection.fromPosition(
            TextPosition(offset: _reportController.text.length),
          );
          setState(() => _isListening = false);
          _pulseController.stop();
        }
      },
    );
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecordingAudio) {
      stopAudioRecordingWeb();
      setState(() => _isRecordingAudio = false);
      return;
    }

    final started = await startAudioRecordingWeb((name, blobUrl) {
      if (!mounted) return;
      setState(() {
        _isRecordingAudio = false;
        _uploadedFiles.add(
          UploadedFile(
            name: name,
            size: 'audio/webm',
            isAudio: true,
            blobUrl: blobUrl,
          ),
        );
      });
      _showSuccessSnack('Đã ghi âm thành file: $name');
    });

    if (!mounted) return;
    if (!started) {
      _showErrorSnack('Không thể truy cập micro trên trình duyệt này.');
      return;
    }

    setState(() => _isRecordingAudio = true);
  }

  // Camera Capture
  void _captureImage() {
    captureImageWeb((name, size, bytes) {
      if (mounted) {
        setState(
          () => _uploadedFiles.add(
            UploadedFile(name: name, size: _formatBytes(size), bytes: bytes),
          ),
        );
        _showSuccessSnack('Đã thêm ảnh chụp: $name');
      }
    });
  }

  // Get GPS Location
  Future<void> _fetchCurrentLocation() async {
    final locationStr = await getLocationWeb();
    if (locationStr != null && mounted) {
      setState(() {
        _locationController.text = locationStr;
      });
    }
  }

  // Edit Location Dialog
  void _showEditLocationDialog() {
    final editController = TextEditingController(text: _locationController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_location_alt_rounded, color: Color(0xFF0A3878)),
            SizedBox(width: 8),
            Text('Sửa địa điểm / Vị trí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A3878))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập hoặc điều chỉnh địa điểm chi tiết:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            TextField(
              controller: editController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập vị trí hoặc địa điểm cụ thể...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _locationController.text = editController.text.trim();
              });
              Navigator.pop(ctx);
              _showSuccessSnack('Đã cập nhật vị trí mới!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A3878),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu vị trí'),
          ),
        ],
      ),
    );
  }

  // File Upload
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _uploadedFiles.addAll(
        result.files
            .where((f) => f.name.isNotEmpty)
            .map(
              (f) => UploadedFile(
                name: f.name,
                size: _formatBytes(f.size),
                bytes: f.bytes,
                path: f.path,
              ),
            ),
      );
    });
  }

  // Download (Web)
  void _downloadFile(UploadedFile file) {
    if (file.blobUrl != null) {
      downloadFileWeb(file.blobUrl, file.name);
    } else {
      _showInfoSnack(
        '"${file.name}" (${file.size}) - File đã được lưu trên máy chủ.',
      );
    }
  }

  void _removeFile(UploadedFile file) {
    setState(() => _uploadedFiles.remove(file));
    _showInfoSnack('Đã xóa "${file.name}".');
  }

  // Language dropdown
  void _showLanguageMenu(BuildContext ctx) {
    final rb = _langKey.currentContext!.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(ctx).overlay!.context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(
      Rect.fromPoints(
        rb.localToGlobal(Offset.zero, ancestor: overlay),
        rb.localToGlobal(rb.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<String>(
      context: ctx,
      position: pos,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      items: [
        _langMenuItem('vi', 'Tiếng Việt', _isVietnamese),
        _langMenuItem('en', 'English', !_isVietnamese),
      ],
    ).then((val) {
      if (val != null) {
        AppLanguage.instance.setLocale(val == 'vi' ? AppLocale.vi : AppLocale.en);
      }
    });
  }

  PopupMenuItem<String> _langMenuItem(String val, String label, bool selected) {
    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Text(
            val == 'vi' ? 'VI' : 'EN',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected
                  ? const Color(0xFF0B6EDB)
                  : const Color(0xFF8AA5C7),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? const Color(0xFF0B6EDB)
                  : const Color(0xFF0A2F5D),
            ),
          ),
          if (selected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0B6EDB)),
          ],
        ],
      ),
    );
  }

  // Notification popup
  void _showNotificationPopup(BuildContext ctx) {
    final rb = _notifKey.currentContext!.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(ctx).overlay!.context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(
      Rect.fromPoints(
        rb.localToGlobal(Offset.zero, ancestor: overlay),
        rb.localToGlobal(rb.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final notifs = [
      _NotifItem(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF1AA06A),
        title: 'Báo cáo #1023 đã được phê duyệt',
        time: '10 phút trước',
      ),
      _NotifItem(
        icon: Icons.info_rounded,
        color: const Color(0xFF0B6EDB),
        title: 'Hệ thống bảo trì lúc 02:00 AM',
        time: '1 giờ trước',
      ),
      _NotifItem(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF77B32),
        title: 'Sự cố khu A cần xử lý ngay',
        time: 'Hôm qua',
      ),
    ];
    showMenu<void>(
      context: ctx,
      position: pos,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
      elevation: 10,
      items: [
        const PopupMenuItem<void>(
          enabled: false,
          height: 40,
          child: Text(
            'Thông báo',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF0A2F5D),
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        ...notifs.map(
          (n) => PopupMenuItem<void>(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: n.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(n.icon, color: n.color, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0A2F5D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8AA5C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<void>(
          height: 40,
          onTap: () {},
          child: const Center(
            child: Text(
              'Xem tất cả thông báo',
              style: TextStyle(
                color: Color(0xFF0B6EDB),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Account Popup / Profile Dialog
  void _showAccountPopup(BuildContext ctx) {
    if (_isLoggedIn) {
      _showAccountProfileDialog(ctx);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    }
  }

  void _showAccountProfileDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AccountProfileDialog(
        userFullName: _userFullName,
        userEmail: _userEmail,
        userIdCode: _userIdCode,
        userDepartment: _userDepartment,
        userRole: _userRole,
        onLogout: _logoutAndReturnToAuth,
      ),
    );
  }

  void _logoutAndReturnToAuth() {
    setState(() => _isLoggedIn = false);
    _showInfoSnack('Đã đăng xuất tài khoản.');
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  Widget _accountChoiceChip({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0B6EDB).withValues(alpha: 0.12)
              : const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0B6EDB) : const Color(0xFFE3ECFF),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.account_circle_outlined,
              size: 16,
              color: selected
                  ? const Color(0xFF0B6EDB)
                  : const Color(0xFF8AA5C7),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF0B6EDB)
                        : const Color(0xFF0A2F5D),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8AA5C7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Submit Report
  Future<void> _submitReport() async {
    final desc = _reportController.text.trim();
    if (desc.isEmpty) {
      _showErrorSnack('Vui lòng nhập nội dung báo cáo trước khi gửi.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final location = _locationController.text.trim();

      final processedFiles = <UploadedFile>[];
      for (final f in _uploadedFiles) {
        Uint8List? bytes = f.bytes;
        if (bytes == null && f.blobUrl != null) {
          try {
            final res = await http.get(Uri.parse(f.blobUrl!));
            if (res.statusCode == 200) {
              bytes = res.bodyBytes;
            }
          } catch (_) {}
        }
        if (bytes == null || bytes.isEmpty) {
          bytes = Uint8List.fromList('File content: ${f.name}'.codeUnits);
        }
        processedFiles.add(
          UploadedFile(
            name: f.name,
            size: f.size,
            bytes: bytes,
            path: f.path,
            isAudio: f.isAudio,
            blobUrl: f.blobUrl,
          ),
        );
      }

      final createdCase = await _caseService.submitReport(
        description: desc,
        location: location,
        reportType: 'Report',
        incidentType: 'Vi phạm quy chế',
        priority: 'Normal',
        userId: _userIdCode,
        files: processedFiles,
      );

      setState(() {
        _isSubmitting = false;
        _reportController.clear();
        _uploadedFiles.clear();
      });

      _fetchHistory();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF1AA06A),
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Gửi báo cáo thành công!',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A2F5D),
                ),
              ),
            ],
          ),
          content: Text(
            'Báo cáo #${createdCase.id} đã được lưu vào Database PostgreSQL với ${createdCase.evidences.length} tệp đính kèm.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6EDB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnack('Lỗi khi gửi báo cáo: $e');
    }
  }

  Future<void> _submitSos() async {
    setState(() => _isSubmitting = true);
    try {
      _showInfoSnack('Đang tự động lấy vị trí định vị GPS khẩn cấp...');
      final gpsLocation = await getLocationWeb();
      String location = _locationController.text.trim();
      if (gpsLocation != null) {
        location = location.isEmpty ? gpsLocation : '$location ($gpsLocation)';
        _locationController.text = location;
      } else if (location.isEmpty) {
        location = 'Vị trí chưa xác định';
      }

      final desc = _reportController.text.trim().isNotEmpty
          ? _reportController.text.trim()
          : 'Yêu cầu cấp cứu / KHẨN CẤP (SOS)';

      final createdCase = await _caseService.submitReport(
        description: desc,
        location: location,
        reportType: 'SOS',
        incidentType: 'Khẩn cấp / SOS',
        priority: 'High',
        userId: _userIdCode,
      );

      setState(() {
        _isSubmitting = false;
      });

      _fetchHistory();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFCF3C3C),
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'SOS đã được gửi!',
                style: TextStyle(
                  color: Color(0xFFCF3C3C),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Yêu cầu khẩn cấp #${createdCase.id} đã được gửi và lưu vào Database PostgreSQL.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCF3C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnack('Lỗi khi gửi SOS: $e');
    }
  }

  // Helpers
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    const u = ['B', 'KB', 'MB', 'GB'];
    var s = bytes.toDouble();
    var i = 0;
    while (s >= 1024 && i < u.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(s >= 10 || i == 0 ? 0 : 1)} ${u[i]}';
  }

  void _showErrorSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFCF3C3C),
    ),
  );
  void _showSuccessSnack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1AA06A),
        ),
      );
  void _showInfoSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3878),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HỆ THỐNG AN TOÀN',
                        style: TextStyle(
                          color: Color(0xFF0A3878),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Cổng báo cáo & An toàn',
                        style: TextStyle(
                          color: Color(0xFFE85D26),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              iconTheme: const IconThemeData(color: Color(0xFF0A3878)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_circle_rounded, color: Color(0xFF0A3878)),
                  onPressed: () => _showAccountPopup(context),
                ),
              ],
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
      body: Column(
        children: [
          if (!isMobile)
            _buildUnifiedHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 24,
                      vertical: isMobile ? 14 : 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: _buildMainPanel(),
                      ),
                    ),
                  ),
                  _buildFooter(theme),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFFE85D26),
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              onTap: _onTabSelected,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.report_problem_outlined),
                  activeIcon: Icon(Icons.report_problem_rounded),
                  label: 'Báo cáo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sos_outlined),
                  activeIcon: Icon(Icons.sos_rounded),
                  label: 'SOS Khẩn cấp',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_edu_outlined),
                  activeIcon: Icon(Icons.history_edu_rounded),
                  label: 'Lịch sử',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildUnifiedHeader(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A3878), Color(0xFFE85D26)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _selectedIndex = 0),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3878),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isVietnamese ? 'AN TOÀN HỌC ĐƯỜNG' : 'CAMPUS SAFETY',
                            style: TextStyle(
                              color: Color(0xFF0A3878),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            _isVietnamese ? 'CỔNG SINH VIÊN' : 'STUDENT PORTAL',
                            style: TextStyle(
                              color: Color(0xFFE85D26),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        final selected = _selectedIndex == index;
                        final isSos = index == 1;

                        return InkWell(
                          onTap: () => _onTabSelected(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: selected
                                  ? (isSos ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: selected
                                  ? Border.all(
                                      color: isSos ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 16,
                                  color: selected
                                      ? (isSos ? const Color(0xFFDC2626) : const Color(0xFF0A3878))
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected
                                        ? (isSos ? const Color(0xFFDC2626) : const Color(0xFF0A3878))
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                ),
                const SizedBox(width: 16),
                _HeaderAction(
                  key: _langKey,
                  label: _isVietnamese ? 'Tiếng Việt' : 'English',
                  icon: Icons.language_rounded,
                  onTap: () => _showLanguageMenu(context),
                ),
                const SizedBox(width: 8),
                _HeaderAction(
                  key: _notifKey,
                  label: _isVietnamese ? 'Thông báo' : 'Notifications',
                  icon: _hasNotification
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  badge: _hasNotification ? '3' : null,
                  onTap: () => _showNotificationPopup(context),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showAccountPopup(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF0A3878).withValues(alpha: 0.12),
                          child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF0A3878)),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _isLoggedIn ? _userFullName : 'Đăng nhập',
                          style: const TextStyle(
                            color: Color(0xFF0A3878),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Đăng xuất',
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 19),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 320,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            color: const Color(0xFF0A3878),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Color(0xFF0A3878),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userFullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_userRole\n$_userDepartment',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                final item = _items[index];
                final selected = _selectedIndex == index;
                final isSos = index == 1;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _onTabSelected(index);
                    if (isDrawer) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isSos
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFF0A3878).withValues(alpha: 0.08))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? (isSos ? const Color(0xFFEF4444) : const Color(0xFF0A3878))
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: selected
                              ? (isSos ? const Color(0xFFEF4444) : const Color(0xFF0A3878))
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: selected
                                      ? (isSos ? const Color(0xFFEF4444) : const Color(0xFF0A3878))
                                      : const Color(0xFF1E293B),
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPanel() {
    final titles = [
      _isVietnamese ? 'BÁO CÁO VI PHẠM & SỰ VIỆC AN TOÀN' : 'CAMPUS VIOLATION & SAFETY REPORT',
      _isVietnamese ? 'PHÁT TÍN HIỆU CỨU HỘ KHẨN CẤP (SOS)' : 'EMERGENCY RESCUE BEACON (SOS)',
      _isVietnamese ? 'LỊCH SỬ BÁO CÁO CỦA BẠN' : 'YOUR REPORT HISTORY',
      _isVietnamese ? 'TƯ VẤN TRỰC TUYẾN VỚI CHUYÊN VIÊN' : 'ONLINE COUNSELING WITH SPECIALIST',
    ];


    final isSos = _selectedIndex == 1;
    final isHistory = _selectedIndex == 2;

    final body = switch (_selectedIndex) {
      1 => _buildSosPanel(),
      2 => _buildHistoryPanel(),
      3 => _buildChatPanel(),
      _ => _buildReportPanel(),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSos
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFE85D26),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titles[_selectedIndex.clamp(0, 3)],
                        style: TextStyle(
                          color: isSos
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF0A3878),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),

                    ],
                  ),
                ),
                if (isHistory)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0A3878)),
                    tooltip: 'Làm mới lịch sử',
                    onPressed: _fetchHistory,
                  ),
              ],
            ),
          ),
          body,
        ],
      ),
    );
  }

  Widget _buildReportPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AudioRecordCard(
                  isListening: _isRecordingAudio,
                  title: _isRecordingAudio
                      ? 'Đang ghi âm...'
                      : 'Ghi âm thành file',
                  onTap: _toggleAudioRecording,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ReportOptionCard(
                  title: 'Tải file lên',
                  icon: Icons.upload_file_rounded,
                  color: const Color(0xFF0A3878),
                  onTap: _pickFiles,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ReportOptionCard(
                  title: 'Chụp hình',
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF10B981),
                  onTap: _captureImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vị trí / Địa điểm',
                  style: TextStyle(
                    color: Color(0xFF0A3878),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF0A3878),
                    ),
                    suffixIcon: Tooltip(
                      message: 'Lấy vị trí GPS trực tiếp',
                      child: InkWell(
                        onTap: _fetchCurrentLocation,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A3878).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF0A3878).withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location_rounded, color: Color(0xFF0A3878), size: 15),
                              SizedBox(width: 4),
                              Text(
                                'Lấy định vị GPS',
                                style: TextStyle(
                                  color: Color(0xFF0A3878),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    hintText: 'Nhập vị trí hoặc địa điểm cụ thể...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0A3878), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nội dung báo cáo',
                  style: TextStyle(
                    color: Color(0xFF0A3878),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isListening
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE2E8F0),
                      width: _isListening ? 1.5 : 1.0,
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: _reportController,
                    maxLines: 7,
                    minLines: 4,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      hintText: 'Mô tả chi tiết nội dung sự việc...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                      suffixIcon: Align(
                        alignment: Alignment.bottomCenter,
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6, right: 4),
                          child: Tooltip(
                            message: 'Nói để nhập văn bản',
                            child: Material(
                              color: _isListening
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _toggleSTT,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    _isListening
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: _isListening
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF64748B),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Các file đã tải lên',
                      style: TextStyle(
                        color: Color(0xFF0A3878),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A3878).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_uploadedFiles.length}',
                        style: const TextStyle(
                          color: Color(0xFF0A3878),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._uploadedFiles.map(
                  (file) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color:
                                (file.isAudio
                                        ? const Color(0xFFE85D26)
                                        : const Color(0xFF0A3878))
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            file.isAudio
                                ? Icons.audio_file_rounded
                                : Icons.insert_drive_file_rounded,
                            color: file.isAudio
                                ? const Color(0xFFE85D26)
                                : const Color(0xFF0A3878),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                file.size,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tải xuống',
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Color(0xFF0A3878),
                            size: 20,
                          ),
                          onPressed: () => _downloadFile(file),
                        ),
                        IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          onPressed: () => _removeFile(file),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? (_isVietnamese ? 'Đang gửi...' : 'Submitting...') : (_isVietnamese ? 'Gửi báo cáo & Lưu DB' : 'Submit Report & Save DB'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3878),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
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

  Widget _buildSosPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFCF3C3C),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isVietnamese ? 'BÁO CÁO KHẨN CẤP (SOS)' : 'EMERGENCY BEACON (SOS)',
                      style: TextStyle(
                        color: Color(0xFFCF3C3C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _isVietnamese ? 'Khi bấm nút SOS, hệ thống sẽ tự động định vị vị trí GPS hiện tại của bạn và gửi tín hiệu cứu hộ tức thì tới Ban Quản Lý.' : 'When pressing SOS, the system will automatically locate your GPS position and send an instant rescue alert to School Security.',
                  style: TextStyle(
                    color: Color(0xFF53709F),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Thẻ vị trí riêng biệt
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A3878).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFF0A3878), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vị trí định vị SOS',
                        style: TextStyle(
                          color: Color(0xFF0A3878),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locationController.text.isNotEmpty
                            ? _locationController.text
                            : 'Tự động định vị vị trí GPS khi bấm SOS',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showEditLocationDialog,
                  icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                  label: const Text('Sửa địa chỉ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3878),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Nút SOS khổng lồ nổi bật
          Center(
            child: GestureDetector(
              onTap: _isSubmitting ? null : _submitSos,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D4D), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 6,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSubmitting)
                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    else ...[
                      const Icon(Icons.sos_rounded, color: Colors.white, size: 56),
                      const SizedBox(height: 4),
                      const Text(
                        'NHẤN ĐỂ GỬI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIncidentTypeVi(String type) {
    final lower = type.toLowerCase().trim();
    if (lower.contains('physical') || lower.contains('violence')) return 'Bạo lực thể chất';
    if (lower.contains('cyber')) return 'Bắt nạt trực tuyến';
    if (lower.contains('bullying')) return 'Bắt nạt học đường';
    if (lower.contains('verbal') || lower.contains('abuse')) return 'Xúc phạm & Đe dọa';
    if (lower.contains('isolation')) return 'Cô lập & Tẩy chay';
    if (lower.contains('vandalism')) return 'Phá hoại tài sản';
    if (lower.contains('theft')) return 'Trộm cắp tài sản';
    if (lower.contains('cheat')) return 'Gian lận học thuật';
    if (lower.contains('sos') || lower.contains('emergency')) return 'Khẩn cấp (SOS)';
    return type.isNotEmpty ? type : 'Vi phạm nội quy';
  }

  String _formatStatusVi(String status) {
    final lower = status.toLowerCase().trim();
    if (lower == 'new' || lower.contains('mới')) return 'Mới tiếp nhận';
    if (lower.contains('progress') || lower.contains('xử lý')) return 'Đang xử lý';
    if (lower.contains('resolved') || lower.contains('giải quyết')) return 'Đã giải quyết';
    if (lower.contains('closed') || lower.contains('đóng')) return 'Đã đóng hồ sơ';
    return status;
  }

  String _formatDescriptionVi(String desc, String type) {
    if (desc.startsWith('Detailed report #') || desc.contains('The student experienced uncomfortable situations')) {
      final viType = _formatIncidentTypeVi(type);
      return 'Báo cáo chi tiết về hành vi $viType đã được gửi đến ban quản lý và cố vấn học tập.';
    }
    return desc;
  }

  Widget _buildHistoryPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử báo cáo trong Database',
                  style: TextStyle(
                    color: Color(0xFF0A3878),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF0A3878),
                  ),
                  tooltip: 'Làm mới',
                  onPressed: _fetchHistory,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_historyCases.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  _isVietnamese ? 'Chưa có báo cáo nào trong Database.' : 'No reports found in Database.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historyCases.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final item = _historyCases[index];
                  final isResolved = item.status.toLowerCase().contains('resolved') ||
                      item.status.toLowerCase().contains('closed') ||
                      item.status.contains('giải quyết');
                  final isProcessing = item.status.toLowerCase().contains('progress') ||
                      item.status.contains('xử lý');

                  final statusColor = isResolved
                      ? const Color(0xFF10B981)
                      : isProcessing
                          ? const Color(0xFFE85D26)
                          : const Color(0xFF0A3878);

                  final viType = _formatIncidentTypeVi(item.incidentType);
                  final viStatus = _formatStatusVi(item.status);
                  final viDesc = _formatDescriptionVi(item.description, item.incidentType);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${item.id} • $viType',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: Color(0xFF0F2942),
                                    ),
                                  ),
                                ),
                                if (item.location.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  Text(
                                    item.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                viStatus,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          viDesc,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            height: 1.45,
                          ),
                        ),
                        if (item.evidences.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: item.evidences
                                .map(
                                  (e) => Chip(
                                    avatar: Icon(
                                      e.fileType == 'image'
                                          ? Icons.image_rounded
                                          : e.fileType == 'audio'
                                          ? Icons.audiotrack_rounded
                                          : Icons.insert_drive_file_rounded,
                                      size: 15,
                                      color: const Color(0xFF0A3878),
                                    ),
                                    label: Text(
                                      e.fileName,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                                    ),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ thông tin Chuyên viên hỗ trợ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFF0A3878),
                      child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuyên viên Hỗ trợ',
                        style: TextStyle(
                          color: Color(0xFF0A3878),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Trực tuyến • Sẵn sàng giải đáp thắc mắc quy chế & sự cố',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                      SizedBox(width: 6),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Khung tin nhắn Chat
          Container(
            height: 380,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView(
              children: [
                // Tin nhắn hệ thống chào mừng
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hệ thống tư vấn trực tuyến',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Tin nhắn từ chuyên viên
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12, right: 40),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào Anh Ly! Chuyên viên Ban Giám Sát & Quy Chế có thể hỗ trợ gì cho bạn hôm nay?',
                          style: TextStyle(color: Color(0xFF1E293B), fontSize: 13.5, height: 1.45),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '08:30 AM',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tin nhắn mẫu từ sinh viên
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12, left: 40),
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A3878),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Dạ chào Chuyên viên, em muốn hỏi về quy trình xử lý báo cáo vi phạm mất trật tự ạ.',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '08:32 AM',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                // Phản hồi chuyên viên
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12, right: 40),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào bạn, khi bạn gửi báo cáo, thông tin sẽ được chuyển ngay tới Ban Quản Lý Khu Vực. Thời gian tiếp nhận thông thường là trong vòng 15 phút.',
                          style: TextStyle(color: Color(0xFF1E293B), fontSize: 13.5, height: 1.45),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '08:33 AM',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Ô nhập tin nhắn & Nút gửi
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn tư vấn...',
                    hintStyle: const TextStyle(color: Color(0xFF8AA5C7), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.sentiment_satisfied_alt_rounded, color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () {},
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A3878),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    _showInfoSnack('Đã gửi tin nhắn tới Chuyên viên!');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF06234B),
      child: Column(
        children: [
          Container(
            height: 3,
            color: const Color(0xFFE85D26),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HỆ THỐNG TIẾP NHẬN BÁO CÁO & AN TOÀN HỌC ĐƯỜNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hotline hỗ trợ: 1900 6868  •  Email: hotro@safety.edu.vn  •  Trực tuyến 24/7',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '© 2026 Campus Safety System',
                          style: TextStyle(color: Colors.white60, fontSize: 11.5),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hệ thống tiếp nhận phản ánh trực tuyến',
                          style: TextStyle(color: Color(0xFFE85D26), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATA CLASSES ──────────────────────────────────────────────────────────────

class _SidebarItem {
  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.subtitle,
  });
  final String title;
  final IconData icon;
  final String subtitle;
}

class _NotifItem {
  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String time;
}

// ─── WIDGETS ───────────────────────────────────────────────────────────────────

class _HeaderAction extends StatefulWidget {
  const _HeaderAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
    this.highlight = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool highlight;

  @override
  State<_HeaderAction> createState() => _HeaderActionState();
}

class _HeaderActionState extends State<_HeaderAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF1F5F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icon,
                    color: _hovered ? const Color(0xFF0A3878) : const Color(0xFF64748B),
                    size: 16,
                  ),
                  if (widget.badge != null)
                    Positioned(
                      top: -6,
                      right: -7,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE85D26),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Center(
                          child: Text(
                            widget.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? const Color(0xFF0A3878) : const Color(0xFF334155),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioRecordCard extends StatelessWidget {
  const _AudioRecordCard({
    required this.isListening,
    required this.title,
    required this.onTap,
  });
  final bool isListening;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ReportOptionCard(
      title: title,
      icon: isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
      color: isListening ? const Color(0xFFEF4444) : const Color(0xFF0A3878),
      onTap: onTap,
    );
  }
}

class _ReportOptionCard extends StatelessWidget {
  const _ReportOptionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

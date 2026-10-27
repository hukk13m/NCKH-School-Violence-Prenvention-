import '../data/case_service.dart';
import 'package:flutter/material.dart';

import '../../auth/domain/auth_models.dart';
import 'web_utils/web_utils.dart';
import 'widgets/account_profile_dialog.dart';
import 'widgets/teacher_admin_dashboard.dart';
import '../../../core/localization/app_language.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final bool isAdmin;

  const TeacherDashboardScreen({super.key, this.isAdmin = false});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  int? _hoveredIndex;

  String _userFullName = 'Trần Anh';
  String _userEmail = 'teacher@school.edu';
  String _userIdCode = 'GV-2026';
  String _userDepartment = 'Khoa Công nghệ Thông tin';
  String _userRole = 'Giảng viên';

  bool _initializedUser = false;
  final TextEditingController _reportController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: 'Khuôn viên trường học');
  String _incidentCategory = 'Bạo lực học đường & Đe dọa';
  String _priorityLevel = 'Nguy cơ cao';
  List<CaseModel> _dbCases = [];
  bool _loadingDbCases = false;
  final CaseService _caseService = CaseService();

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.localeNotifier.addListener(_onLocaleChanged);
    _loadCases();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.instance.localeNotifier.removeListener(_onLocaleChanged);
    _reportController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    setState(() => _loadingDbCases = true);
    final bool isAdmin = widget.isAdmin || _userRole.contains('Quản trị');
    try {
      final cases = await _caseService.fetchCases(
        userId: _userEmail,
        role: isAdmin ? 'admin' : 'teacher',
      );
      if (mounted) {
        setState(() {
          _dbCases = cases;
          _loadingDbCases = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDbCases = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedUser) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is AuthSession) {
        setState(() {
          _userFullName = args.fullName;
          _userEmail = args.email;
          _userIdCode = args.userId.toUpperCase();
          _userDepartment = args.department ?? 'Ban Giám hiệu & Quản trị';
          _userRole = args.role == AuthRole.admin
              ? 'Quản trị viên'
              : 'Giảng viên / Cố vấn';
        });
        _loadCases();
      } else if (widget.isAdmin) {
        setState(() {
          _userRole = 'Quản trị viên';
        });
      }
      _initializedUser = true;
    }
  }

  AppStrings get s => AppLanguage.instance.s;

  List<_TeacherTabItem> get _tabs => [
    _TeacherTabItem(title: s.teacherTabOverview, icon: Icons.dashboard_outlined),
    _TeacherTabItem(title: s.teacherTabCreate, icon: Icons.add_circle_outline_rounded),
    _TeacherTabItem(title: s.teacherTabSos, icon: Icons.emergency_outlined),
    _TeacherTabItem(title: s.teacherTabHandled, icon: Icons.folder_shared_outlined),
    _TeacherTabItem(title: s.teacherTabChat, icon: Icons.forum_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildUnifiedHeader(),
          Expanded(
            child: _selectedIndex == 0
                ? TeacherAdminDashboard(
                    key: ValueKey(_userEmail),
                    userFullName: _userFullName,
                    userRole: _userRole,
                    userDepartment: _userDepartment,
                    userId: _userEmail,
                    isAdmin: widget.isAdmin,
                    onCreateReportPressed: () {
                      setState(() => _selectedIndex = 1);
                    },
                  )
                : _buildSubPanels(),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF033877),
              unselectedItemColor: const Color(0xFF64748B),
              onTap: (idx) => setState(() => _selectedIndex = idx),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard_rounded),
                  label: 'Tổng quan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  activeIcon: Icon(Icons.add_circle_rounded),
                  label: 'Báo cáo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emergency_outlined),
                  activeIcon: Icon(Icons.emergency_rounded),
                  label: 'SOS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_shared_outlined),
                  activeIcon: Icon(Icons.folder_shared_rounded),
                  label: 'Hồ sơ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_outlined),
                  activeIcon: Icon(Icons.forum_rounded),
                  label: 'Tư vấn',
                ),
              ],
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildUnifiedHeader() {
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
                colors: [Color(0xFF033877), Color(0xFFE85D26)],
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
                          color: const Color(0xFF0F2942),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.brandTitle,
                            style: TextStyle(
                              color: Color(0xFF033877),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            widget.isAdmin || _userRole.contains('Quản trị')
                                ? s.adminPortal
                                : s.teacherPortal,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
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
                        children: List.generate(_tabs.length, (index) {
                        final tab = _tabs[index];
                        final isSelected = _selectedIndex == index;
                        final isSos = index == 2;

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            if (index == 2 || index == 3) _loadCases();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isSos ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
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
                                  tab.icon,
                                  size: 16,
                                  color: isSelected
                                      ? (isSos ? const Color(0xFFDC2626) : const Color(0xFF0F2942))
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  tab.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isSos ? const Color(0xFFDC2626) : const Color(0xFF0F2942))
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
                if (widget.isAdmin || _userRole.contains('Quản trị')) ...[
                  OutlinedButton.icon(
                    onPressed: () => openUrl('/admin/'),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 15),
                    label: const Text('Admin DB',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF033877),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const LanguageSwitcherButton(),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showAccountDialog(),
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
                          backgroundColor: const Color(0xFF033877).withValues(alpha: 0.12),
                          child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF033877)),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _userFullName,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
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

  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AccountProfileDialog(
        userFullName: _userFullName,
        userEmail: _userEmail,
        userIdCode: _userIdCode,
        userDepartment: _userDepartment,
        userRole: _userRole,
        onLogout: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed('/auth');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-Panels (Report creation, SOS dispatch, Cases History, Chat)
  // ---------------------------------------------------------------------------
  Widget _buildSubPanels() {
    final Widget panel = switch (_selectedIndex) {
      1 => _buildTeacherReportForm(),
      2 => _buildSosDispatchCenter(),
      3 => _buildHandledCasesHistory(),
      4 => _buildAdvisoryChat(),
      _ => const SizedBox.shrink(),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: panel,
      ),
    );
  }

  // Form tạo báo cáo vi phạm dành cho giáo viên / cán bộ
  Widget _buildTeacherReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D26),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TẠO BÁO CÁO VI PHẠM & SỰ CỐ HỌC ĐƯỜNG',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF033877),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Ghi nhận sự cố do giáo viên quan sát thấy hoặc báo cáo thay mặt học sinh.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Form inputs
            const Text('Loại sự việc / Hành vi vi phạm',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _incidentCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Bạo lực học đường & Đe dọa',
                    child: Text('Bạo lực học đường & Đe dọa')),
                DropdownMenuItem(
                    value: 'Bắt nạt trực tuyến (Cyberbullying)',
                    child: Text('Bắt nạt trực tuyến (Cyberbullying)')),
                DropdownMenuItem(
                    value: 'Cô lập xã hội & Tẩy chay',
                    child: Text('Cô lập xã hội & Tẩy chay')),
                DropdownMenuItem(
                    value: 'Xúc phạm danh dự / Body Shaming',
                    child: Text('Xúc phạm danh dự / Body Shaming')),
                DropdownMenuItem(
                    value: 'Vi phạm an ninh trật tự khuôn viên',
                    child: Text('Vi phạm an ninh trật tự khuôn viên')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _incidentCategory = val);
              },
            ),
            const SizedBox(height: 16),

            const Text('Vị trí / Địa điểm xảy ra',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Mô tả chi tiết nội dung sự việc',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _reportController,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: 'Nhập diễn biến sự việc, các đối tượng liên quan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                if (_reportController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập mô tả sự việc!'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                try {
                  await _caseService.submitReport(
                    description: _reportController.text.trim(),
                    location: _locationController.text.trim(),
                    reportType: 'Báo cáo Giảng viên',
                    incidentType: _incidentCategory,
                    priority: _priorityLevel,
                    userId: _userEmail,
                  );
                  _reportController.clear();
                  _loadCases();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu báo cáo vi phạm vào Database thành công!'),
                        backgroundColor: Color(0xFF033877),
                      ),
                    );
                    setState(() => _selectedIndex = 0);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi gửi báo cáo: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Gửi báo cáo sự cố lên Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF033877),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosDispatchCenter() {
    final sosCases = _dbCases.where((c) {
      final p = c.priority.toLowerCase();
      final t = c.incidentType.toLowerCase();
      final r = c.reportType.toLowerCase();
      return p == 'critical' || p == 'high' || r == 'sos' || t.contains('sos') || c.riskScore >= 0.65;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.sosDispatchTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.sosDispatchSub(sosCases.length),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF033877)),
                ),
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF033877)), onPressed: _loadCases, tooltip: 'Làm mới'),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingDbCases)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (sosCases.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 48, color: Color(0xFF10B981)),
                    SizedBox(height: 12),
                    Text(
                      s.noSosTitle,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      s.noSosDesc,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else ...[
              for (final c in sosCases.take(20))
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(6)),
                        child: Text('#' + c.id.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.incidentType + ' - ' + c.reporterName + ' (' + c.location + ')', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 3),
                            Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                        child: Text('Risk: ' + c.riskScore.toStringAsFixed(2), style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHandledCasesHistory() {
    final handledCases = _dbCases.where((c) {
      final s = c.status.toLowerCase();
      return s == 'resolved' || s == 'closed';
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.handledCasesTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF033877),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.handledCasesSub(handledCases.length),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF033877)),
                ),
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF033877)), onPressed: _loadCases, tooltip: 'Làm mới'),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingDbCases)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (handledCases.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text(
                      s.noHandledTitle,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      s.noHandledDesc,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else ...[
              for (final c in handledCases.take(30))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hồ sơ #CASE-' + c.id.toString().padLeft(4, '0') + ': ' + c.incidentType + ' - ' + c.reporterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(c.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                        child: Text(c.status, style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 11.5)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryChat() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(26),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KÊNH TRAO ĐỔI VỚI CHUYÊN VIÊN TÂM LÝ & BAN QUẢN LÝ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF033877),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _TeacherTabItem {
  final String title;
  final IconData icon;

  const _TeacherTabItem({
    required this.title,
    required this.icon,
  });
}

import '../../data/case_service.dart';
import '../../../../core/localization/app_language.dart';
import 'package:flutter/material.dart';

/// Models for Incident & Explainable AI analysis according to Proposal
class AdminIncidentModel {
  final String id;
  final String reporterName;
  final bool isAnonymous;
  final String incidentType;
  final String location;
  final String description;
  final List<String> flaggedKeywords;
  final DateTime createdAt;
  String status; // 'New', 'In Progress', 'Resolved', 'Escalated', 'Closed'
  final double toxicityScore; // T
  final double sentimentScore; // S
  final double keywordScore; // K
  final double frequencyScore; // F
  final double historyScore; // H
  final String aiRationale;
  final List<String> evidenceThumbnails;
  String? interventionNotes;
  final double? explicitRiskScore;

  AdminIncidentModel({
    required this.id,
    required this.reporterName,
    required this.isAnonymous,
    required this.incidentType,
    required this.location,
    required this.description,
    required this.flaggedKeywords,
    required this.createdAt,
    required this.status,
    required this.toxicityScore,
    required this.sentimentScore,
    required this.keywordScore,
    required this.frequencyScore,
    required this.historyScore,
    required this.aiRationale,
    this.evidenceThumbnails = const [],
    this.interventionNotes,
    this.explicitRiskScore,
  });

  /// Formula from Proposal Section 5.2.3:
  /// RiskScore = 0.35*T + 0.20*S + 0.15*K + 0.15*F + 0.15*H
  double get riskScore =>
      explicitRiskScore ??
      ((0.35 * toxicityScore) +
      (0.20 * sentimentScore) +
      (0.15 * keywordScore) +
      (0.15 * frequencyScore) +
      (0.15 * historyScore));

  String get riskLevel {
    final s = riskScore;
    if (s >= 0.80) return 'Khẩn cấp';
    if (s >= 0.65) return 'Nguy cơ cao';
    if (s >= 0.35) return 'Trung bình';
    return 'Thấp';
  }

  Color get riskColor {
    final s = riskScore;
    if (s >= 0.80) return const Color(0xFFEF4444); // Crimson Red
    if (s >= 0.65) return const Color(0xFFF97316); // Amber Orange
    if (s >= 0.35) return const Color(0xFFF59E0B); // Warm Gold
    return const Color(0xFF10B981); // Emerald Green
  }
}

class TeacherAdminDashboard extends StatefulWidget {
  final VoidCallback onCreateReportPressed;
  final String userFullName;
  final String userRole;
  final String userDepartment;
  final String userId;
  final bool isAdmin;

  const TeacherAdminDashboard({
    super.key,
    required this.onCreateReportPressed,
    required this.userFullName,
    required this.userRole,
    required this.userDepartment,
    this.userId = '',
    this.isAdmin = false,
  });

  @override
  State<TeacherAdminDashboard> createState() => _TeacherAdminDashboardState();
}

class _TeacherAdminDashboardState extends State<TeacherAdminDashboard> {
  String _selectedFilterTab = 'Tất cả';
  String _searchQuery = '';
  String _selectedTimeRange = 'Hôm nay';
  bool _isLoading = false;
  final CaseService _caseService = CaseService();

  late List<AdminIncidentModel> _incidents;

  AppStrings get s => AppLanguage.instance.s;

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.localeNotifier.addListener(_onLocaleChanged);
    _incidents = [];
    _fetchRealIncidents();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.instance.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TeacherAdminDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.isAdmin != widget.isAdmin) {
      _fetchRealIncidents();
    }
  }

  Future<void> _fetchRealIncidents() async {
    setState(() => _isLoading = true);
    try {
      final cases = await _caseService.fetchCases(
        userId: widget.userId,
        role: widget.isAdmin ? 'admin' : 'teacher',
      );
      if (mounted) {
        setState(() {
          _incidents = cases.map(_mapCaseToIncident).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  AdminIncidentModel _mapCaseToIncident(CaseModel c) {
    final rScore = c.riskScore > 0 ? c.riskScore : 0.45;
    final toxic = (rScore * 1.05).clamp(0.0, 1.0);
    final sent = (rScore * 0.95).clamp(0.0, 1.0);
    final keyw = rScore;
    final freq = (rScore * 0.90).clamp(0.0, 1.0);
    final hist = (rScore * 0.85).clamp(0.0, 1.0);

    return AdminIncidentModel(
      id: 'CASE-#${c.id.toString().padLeft(4, "0")}',
      reporterName: c.reporterName.isNotEmpty ? c.reporterName : (c.isAnonymous ? 'Ẩn danh' : 'Học sinh / Sinh viên'),
      isAnonymous: c.isAnonymous,
      incidentType: c.incidentType,
      location: c.location.isNotEmpty ? c.location : 'Khuôn viên trường học',
      description: c.description,
      flaggedKeywords: _extractKeywords(c.description, c.incidentType),
      createdAt: DateTime.tryParse(c.createdAt) ?? DateTime.now(),
      status: c.status,
      toxicityScore: toxic,
      sentimentScore: sent,
      keywordScore: keyw,
      frequencyScore: freq,
      historyScore: hist,
      aiRationale: c.aiRecommendation.isNotEmpty
          ? c.aiRecommendation
          : 'Hệ thống AI ghi nhận rủi ro $rScore dựa trên loại vi phạm ${c.incidentType} và nội dung phản ánh.',
      evidenceThumbnails: c.evidences.map((e) => e.fileName).toList(),
      interventionNotes: null,
      explicitRiskScore: rScore,
    );
  }

  List<String> _extractKeywords(String desc, String type) {
    final keywords = <String>[];
    final wordsToCheck = [
      'bạo lực', 'đe dọa', 'cô lập', 'chửi bới', 'đánh nhau', 'xúc phạm',
      'tẩy chay', 'gian lận', 'cheating', 'violence', 'bullying', 'abuse',
      'theft', 'vandalism', 'cyberbullying', 'physical violence'
    ];
    final lower = '$desc $type'.toLowerCase();
    for (final w in wordsToCheck) {
      if (lower.contains(w) && !keywords.contains(w)) {
        keywords.add(w);
      }
    }
    if (keywords.isEmpty && type.isNotEmpty) {
      keywords.add(type);
    }
    return keywords;
  }

  void _loadSampleIncidents() {
    _incidents = [
      AdminIncidentModel(
        id: 'SOS-2026-0042',
        reporterName: 'Tín hiệu SOS Khẩn cấp',
        isAnonymous: false,
        incidentType: 'Cầu cứu khẩn cấp (SOS)',
        location: 'Hành lang Tầng 3 - Tòa nhà Trung tâm',
        description:
            'Tín hiệu SOS kích hoạt trực tiếp từ học sinh kèm định vị GPS. Phát hiện nhóm người chặn đường đe dọa bạo lực thể chất và ép buộc ra cổng sau.',
        flaggedKeywords: ['chặn đường', 'đe dọa', 'bạo lực', 'ép buộc'],
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        status: 'In Progress',
        toxicityScore: 0.96,
        sentimentScore: 0.94,
        keywordScore: 0.95,
        frequencyScore: 0.90,
        historyScore: 0.92,
        aiRationale:
            'Nguy cơ khẩn cấp (RiskScore = 0.94): Kích hoạt tín hiệu SOS kèm định vị khẩn cấp, phát hiện từ khóa bạo lực thể chất trực tiếp và mức độ tiêu cực cực cao.',
        evidenceThumbnails: ['GPS_Location_Pin.png', 'Audio_Record_01.wav'],
        interventionNotes:
            'Đội Tuần tra & Cố vấn học tập đã có mặt tại hiện trường lúc 14:15 để bảo vệ học sinh.',
      ),
      AdminIncidentModel(
        id: 'CASE-2026-0142',
        reporterName: 'Trần Minh Quang',
        isAnonymous: false,
        incidentType: 'Đe dọa & Bạo lực học đường',
        location: 'Cổng sau trường học & Sân thể thao',
        description:
            'Bạn N. cùng nhóm bạn lớp bên nhắn trong nhóm rằng sẽ chặn đánh em sau giờ học tan trường và kêu mọi người cô lập không cho ai chơi với em nữa.',
        flaggedKeywords: ['đánh', 'sau giờ học', 'chặn', 'cô lập', 'không chơi'],
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 25)),
        status: 'New',
        toxicityScore: 0.92,
        sentimentScore: 0.86,
        keywordScore: 0.90,
        frequencyScore: 0.75,
        historyScore: 0.85,
        aiRationale:
            'Nguy cơ cao (RiskScore = 0.87): Phát hiện ý định đe dọa bạo lực thể chất cụ thể kèm địa điểm/thời gian xảy ra và dấu hiệu cô lập xã hội lặp lại.',
        evidenceThumbnails: ['Screenshot_Threat_Msg.jpg'],
      ),
      AdminIncidentModel(
        id: 'CYBER-2026-0089',
        reporterName: 'Ẩn danh',
        isAnonymous: true,
        incidentType: 'Bắt nạt trực tuyến (Cyberbullying)',
        location: 'Nhóm mạng xã hội & Diễn đàn sinh viên',
        description:
            'Ảnh chụp màn hình các bài viết và bình luận miệt thị ngoại hình (body shaming), bôi nhọ danh dự và đe dọa phát tán thông tin riêng tư trong nhóm chat.',
        flaggedKeywords: ['body shaming', 'bôi nhọ', 'phát tán', 'dọa đăng ảnh'],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'In Progress',
        toxicityScore: 0.84,
        sentimentScore: 0.80,
        keywordScore: 0.75,
        frequencyScore: 0.65,
        historyScore: 0.60,
        aiRationale:
            'Nguy cơ cao (RiskScore = 0.75): Trích xuất văn bản OCR phát hiện xúc phạm danh dự nghiêm trọng, ngôn ngữ thù ghét và đe dọa lan truyền dữ liệu nhạy cảm.',
        evidenceThumbnails: ['OCR_Screenshot_Chat1.png', 'OCR_Screenshot_Post.png'],
        interventionNotes:
            'Đã yêu cầu ban quản trị nhóm ẩn bài viết, chuyển thông tin cho chuyên viên tâm lý hỗ trợ em.',
      ),
      AdminIncidentModel(
        id: 'CASE-2026-0138',
        reporterName: 'Ẩn danh (#ANON-4912)',
        isAnonymous: true,
        incidentType: 'Cô lập xã hội & Tẩy chay',
        location: 'Phòng học 402 - Khu Giảng đường A',
        description:
            'Em xin phản ánh hiện tượng cả nhóm tẩy chay, đuổi bạn cùng bàn ra khỏi nhóm học tập và không cho tham gia hoạt động nhóm trong suốt 2 tuần qua.',
        flaggedKeywords: ['tẩy chay', 'đuổi khỏi nhóm', 'cô lập'],
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        status: 'In Progress',
        toxicityScore: 0.45,
        sentimentScore: 0.70,
        keywordScore: 0.55,
        frequencyScore: 0.60,
        historyScore: 0.40,
        aiRationale:
            'Nguy cơ trung bình (RiskScore = 0.53): Dấu hiệu cô lập xã hội kéo dài, cảm xúc tiêu cực đáng kể nhưng chưa phát hiện bạo lực thể chất tức thời.',
        evidenceThumbnails: [],
        interventionNotes:
            'Giáo viên chủ nhiệm đã trao đổi riêng với ban cán sự lớp để chấn chỉnh tinh thần đoàn kết.',
      ),
      AdminIncidentModel(
        id: 'CASE-2026-0131',
        reporterName: 'Lê Hoàng Nam',
        isAnonymous: false,
        incidentType: 'Xung đột & Xúc phạm lời nói',
        location: 'Khu vực Căn-tin trung tâm',
        description:
            'Cự cãi to tiếng và xúc phạm lẫn nhau do va chạm xe trong bãi giữ xe, chưa xảy ra xô xát thể chất.',
        flaggedKeywords: ['cự cãi', 'xúc phạm'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Resolved',
        toxicityScore: 0.35,
        sentimentScore: 0.40,
        keywordScore: 0.30,
        frequencyScore: 0.20,
        historyScore: 0.15,
        aiRationale:
            'Nguy cơ thấp (RiskScore = 0.30): Mâu thuẫn bộc phát cá nhân, không có tiền sử lặp lại, hai bên đã chủ động giảng hòa.',
        evidenceThumbnails: [],
        interventionNotes:
            'Bảo vệ và Cố vấn học tập đã lập biên bản nhắc nhở, hai sinh viên đã bắt tay xin lỗi.',
      ),
    ];
  }

  List<AdminIncidentModel> get _filteredIncidents {
    return _incidents.where((item) {
      // Tab filter
      if (_selectedFilterTab == 'Khẩn cấp / SOS' && item.riskScore < 0.80) {
        return false;
      }
      if (_selectedFilterTab == 'Cyberbullying' &&
          !item.incidentType.toLowerCase().contains('cyber')) {
        return false;
      }
      if (_selectedFilterTab == 'Đang xử lý' && item.status != 'In Progress') {
        return false;
      }
      if (_selectedFilterTab == 'Đã giải quyết' && item.status != 'Resolved') {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = item.id.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.incidentType.toLowerCase().contains(q) ||
            item.reporterName.toLowerCase().contains(q);
        if (!match) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore)); // Sort by RiskScore
  }

  @override
  Widget build(BuildContext context) {
    final urgentCount = _incidents.where((i) => i.riskScore >= 0.80).length;
    final highRiskCount = _incidents
        .where((i) => i.riskScore >= 0.65 && i.riskScore < 0.80)
        .length;
    final inProgressCount =
        _incidents.where((i) => i.status == 'In Progress').length;
    final resolvedCount =
        _incidents.where((i) => i.status == 'Resolved').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // 1. Top Greeting & Quick Action Header
          _buildTopBanner(),
          const SizedBox(height: 24),

          // 2. Risk KPI Metric Cards
          _buildKpiMetrics(
            urgentCount: urgentCount,
            highRiskCount: highRiskCount,
            inProgressCount: inProgressCount,
            resolvedCount: resolvedCount,
          ),
          const SizedBox(height: 24),

          // 3. Visual Analytics (Charts: Categories & Severity breakdown)
          _buildVisualAnalytics(),
          const SizedBox(height: 24),

          // 4. Incident Priority Queue Table with Explainable AI & Actions
          _buildIncidentQueueSection(),
        ],
      ),
    ),
    ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Banner
  // ---------------------------------------------------------------------------
  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2942).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF0F2942),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.isVi ? 'TRUNG TÂM GIÁM SÁT AN TOÀN HỌC ĐƯỜNG' : 'CAMPUS SAFETY MONITORING CENTER',
                      style: TextStyle(
                        color: Color(0xFF0F2942),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            s.isVi ? 'ĐỒNG BỘ DỮ LIỆU' : 'DATA SYNCED',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 19),
                      tooltip: 'Tải lại dữ liệu từ Database',
                      onPressed: _fetchRealIncidents,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kính chào ${widget.userFullName} (${widget.userRole} • ${widget.userDepartment})',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: widget.onCreateReportPressed,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
            label: Text(
              s.isVi ? 'Tạo phản ánh mới' : 'Record Incident',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2942),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KPI Metrics (4 Cards)
  // ---------------------------------------------------------------------------
  Widget _buildKpiMetrics({
    required int urgentCount,
    required int highRiskCount,
    required int inProgressCount,
    required int resolvedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard(
              title: s.isVi ? 'Khẩn cấp / SOS' : 'Critical / SOS',
              value: '$urgentCount',
              icon: Icons.emergency_rounded,
              color: const Color(0xFFEF4444), // Red
              width: cardWidth,
            ),
            _kpiCard(
              title: s.isVi ? 'Nguy cơ cao' : 'High Risk',
              value: '$highRiskCount',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFF97316), // Orange
              width: cardWidth,
            ),
            _kpiCard(
              title: s.isVi ? 'Đang thụ lý' : 'In Progress',
              value: '$inProgressCount',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFF0284C7), // Blue
              width: cardWidth,
            ),
            _kpiCard(
              title: s.isVi ? 'Đã giải quyết' : 'Resolved',
              value: '$resolvedCount',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF10B981), // Green
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Visual Analytics (Charts)
  // ---------------------------------------------------------------------------
  Widget _buildVisualAnalytics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF033877),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân tích cơ cấu vi phạm & Mức độ rủi ro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF033877),
                      ),
                    ),

                  ],
                ),
              ),
              // Time Range Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTimeRange,
                    isDense: true,
                    style: const TextStyle(
                      color: Color(0xFF033877),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: Color(0xFF033877)),
                    items: const [
                      DropdownMenuItem(
                          value: 'Hôm nay', child: Text('Hôm nay')),
                      DropdownMenuItem(
                          value: '7 ngày qua', child: Text('7 ngày qua')),
                      DropdownMenuItem(
                          value: '30 ngày qua', child: Text('30 ngày qua')),
                      DropdownMenuItem(
                          value: 'Học kỳ 1', child: Text('Học kỳ 1')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimeRange = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal Progress breakdown bars
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isVi ? 'Phân loại hành vi vi phạm phổ biến' : 'Common Incident Categories',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDynamicCategoryBars(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isVi ? 'Tỷ lệ phân tầng nguy cơ (Risk Severity)' : 'Risk Severity Breakdown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _severityRatioBar(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(String label, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            Text(
              '${(ratio * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicCategoryBars() {
    if (_incidents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Đang tải dữ liệu thực tế từ Database...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      );
    }
    final counts = <String, int>{};
    for (final inc in _incidents) {
      final t = inc.incidentType.isNotEmpty ? inc.incidentType : 'Khác';
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topList = sorted.take(4).toList();
    final total = _incidents.length;
    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: List.generate(topList.length, (i) {
        final entry = topList[i];
        final ratio = entry.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _categoryBar('${entry.key} (${entry.value} vụ)', ratio, colors[i % colors.length]),
        );
      }),
    );
  }

  Widget _severityRatioBar() {
    final total = _incidents.isEmpty ? 1 : _incidents.length;
    final urgent = _incidents.where((i) => i.riskScore >= 0.80).length;
    final high = _incidents.where((i) => i.riskScore >= 0.65 && i.riskScore < 0.80).length;
    final medium = _incidents.where((i) => i.riskScore >= 0.35 && i.riskScore < 0.65).length;
    final low = _incidents.where((i) => i.riskScore < 0.35).length;

    final uPct = (urgent / total * 100).toInt();
    final hPct = (high / total * 100).toInt();
    final mPct = (medium / total * 100).toInt();
    final lPct = (low / total * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: urgent > 0 ? urgent : 1, child: Container(color: const Color(0xFFEF4444))),
                  Expanded(flex: high > 0 ? high : 1, child: Container(color: const Color(0xFFF97316))),
                  Expanded(flex: medium > 0 ? medium : 1, child: Container(color: const Color(0xFFF59E0B))),
                  Expanded(flex: low > 0 ? low : 1, child: Container(color: const Color(0xFF10B981))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(color: const Color(0xFFEF4444), label: 'Khẩn cấp ($urgent - $uPct%)'),
              _LegendItem(color: const Color(0xFFF97316), label: 'Nguy cơ cao ($high - $hPct%)'),
              _LegendItem(color: const Color(0xFFF59E0B), label: 'Trung bình ($medium - $mPct%)'),
              _LegendItem(color: const Color(0xFF10B981), label: 'Thấp ($low - $lPct%)'),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Incident Priority Queue Section
  // ---------------------------------------------------------------------------
  Widget _buildIncidentQueueSection() {
    final list = _filteredIncidents;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title & Search/Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D26), // Coral
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isVi ? 'Danh sách vụ việc ưu tiên (${_filteredIncidents.length} / ${_incidents.length} từ Database)' : 'Priority Incident Queue (${_filteredIncidents.length} / ${_incidents.length} from DB)',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF033877),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Search Input
                SizedBox(
                  width: 260,
                  height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: s.searchHint,
                      hintStyle: const TextStyle(fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Color(0xFF64748B)),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tab Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              children: [
                'Tất cả',
                'Khẩn cấp / SOS',
                'Cyberbullying',
                'Đang xử lý',
                'Đã giải quyết',
              ].map((tab) {
                final isSelected = _selectedFilterTab == tab;
                return ChoiceChip(
                  label: Text(tab),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilterTab = tab),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  selectedColor: const Color(0xFF033877),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF033877)),
            ),

          // Incident List / Table
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Không tìm thấy vụ việc nào phù hợp với bộ lọc hiện tại.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (ctx, idx) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildIncidentRow(item);
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Incident Row
  // ---------------------------------------------------------------------------
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

  String _formatDescriptionVi(String desc, String type) {
    if (desc.startsWith('Detailed report #') || desc.contains('The student experienced uncomfortable situations')) {
      final viType = _formatIncidentTypeVi(type);
      return 'Hồ sơ ghi nhận vụ việc về hành vi $viType tại trường. Người báo cáo phản ánh tình huống bị ảnh hưởng tâm lý và đề nghị can thiệp xác minh.';
    }
    return desc;
  }

  Widget _buildIncidentRow(AdminIncidentModel item) {
    final viType = _formatIncidentTypeVi(item.incidentType);
    final viDesc = _formatDescriptionVi(item.description, item.incidentType);

    return InkWell(
      onTap: () => _openIncidentDetailDialog(item),
      hoverColor: const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code, Type Badge, Reporter, Status, Timestamp
            Row(
              children: [
                Text(
                  item.id,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    viType,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: item.isAnonymous
                        ? const Color(0xFFFAF5FF)
                        : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isAnonymous ? const Color(0xFFE9D5FF) : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Text(
                    item.isAnonymous ? 'Ẩn danh' : item.reporterName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: item.isAnonymous ? const Color(0xFF7E22CE) : const Color(0xFF0369A1),
                    ),
                  ),
                ),
                const Spacer(),
                _statusBadge(item.status),
                const SizedBox(width: 12),
                Text(
                  _formatTimestamp(item.createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description Body
            Text(
              viDesc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),

            // Footer Row: Location, Evidence, Risk Level capsule, Action
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  item.location.isNotEmpty ? item.location : 'Khuôn viên trường học',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (item.evidenceThumbnails.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 3),
                  Text(
                    '${item.evidenceThumbnails.length} minh chứng',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
                const Spacer(),
                // Risk Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: item.riskColor),
                      const SizedBox(width: 4),
                      Text(
                        '${item.riskLevel} (${item.riskScore.toStringAsFixed(2)})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: item.riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status) {
      case 'New':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = s.isVi ? 'Mới tiếp nhận' : 'New';
        break;
      case 'In Progress':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        label = s.isVi ? 'Đang thụ lý' : 'In Progress';
        break;
      case 'Resolved':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        label = s.isVi ? 'Đã giải quyết' : 'Resolved';
        break;
      case 'Closed':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = s.isVi ? 'Đã đóng hồ sơ' : 'Closed';
        break;
      case 'Escalated':
        bg = const Color(0xFFFAF5FF);
        fg = const Color(0xFF7E22CE);
        label = s.isVi ? 'Đã chuyển cấp' : 'Escalated';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Case Detail & Explainable AI Dialog (Modal)
  // ---------------------------------------------------------------------------
  void _openIncidentDetailDialog(AdminIncidentModel item) {
    final notesController =
        TextEditingController(text: item.interventionNotes ?? '');
    String currentStatus = item.status;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                width: 780,
                constraints: const BoxConstraints(maxHeight: 700),
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dialog Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.riskColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: item.riskColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_rounded,
                                  size: 16, color: item.riskColor),
                              const SizedBox(width: 6),
                              Text(
                                '${item.riskLevel.toUpperCase()} (RiskScore: ${item.riskScore.toStringAsFixed(2)})',
                                style: TextStyle(
                                  color: item.riskColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF033877),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Basic info card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          size: 16, color: Color(0xFF033877)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Thông tin phản ánh & Minh chứng số',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF033877),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Ghi nhận: ${_formatTimestamp(item.createdAt)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Loại vi phạm: ${item.incidentType}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vị trí / Kênh diễn ra: ${item.location}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Nội dung tố giác chi tiết:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (item.evidenceThumbnails.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: item.evidenceThumbnails
                                          .map((ev) => Chip(
                                                avatar: const Icon(
                                                    Icons.file_present_rounded,
                                                    size: 15),
                                                label: Text(ev,
                                                    style: const TextStyle(
                                                        fontSize: 11.5)),
                                                backgroundColor: Colors.white,
                                                side: const BorderSide(
                                                    color: Color(0xFFCBD5E1)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Explainable AI (XAI) Analysis Breakdown
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4), // Soft Mint
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome,
                                          size: 16, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Bóc tách Phân tích AI (Explainable AI - XAI)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Formula: 0.35T + 0.20S + 0.15K + 0.15F + 0.15H',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // AI 5 component breakdown
                                  _xaiIndicator(
                                      'T - Độ độc hại / Đe dọa (Toxicity/Threat)',
                                      item.toxicityScore,
                                      0.35),
                                  const SizedBox(height: 6),
                                  _xaiIndicator(
                                      'S - Cảm xúc tiêu cực (Sentiment Negativity)',
                                      item.sentimentScore,
                                      0.20),
                                  const SizedBox(height: 6),
                                  _xaiIndicator(
                                      'K - Từ khóa nguy cơ cao (Keyword Severity)',
                                      item.keywordScore,
                                      0.15),
                                  const SizedBox(height: 6),
                                  _xaiIndicator(
                                      'F - Tần suất lặp lại (Frequency)',
                                      item.frequencyScore,
                                      0.15),
                                  const SizedBox(height: 6),
                                  _xaiIndicator(
                                      'H - Tiền sử vi phạm liên quan (History)',
                                      item.historyScore,
                                      0.15),
                                  const SizedBox(height: 12),

                                  // Rationale text
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFF86EFAC)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                            Icons.lightbulb_outline_rounded,
                                            size: 16,
                                            color: Color(0xFF16A34A)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.aiRationale,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF14532D),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Human Intervention & Actions (Human-in-the-loop)
                            const Text(
                              'Can thiệp có con người giám sát (Human Intervention)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF033877),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status changer dropdown & Escalate button
                            Row(
                              children: [
                                const Text('Cập nhật trạng thái:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentStatus,
                                      isDense: true,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'New',
                                            child: Text('Mới ghi nhận')),
                                        DropdownMenuItem(
                                            value: 'In Progress',
                                            child: Text('Đang thụ lý')),
                                        DropdownMenuItem(
                                            value: 'Resolved',
                                            child: Text('Đã giải quyết')),
                                        DropdownMenuItem(
                                            value: 'Escalated',
                                            child:
                                                Text('Chuyển cấp khẩn cấp')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(
                                              () => currentStatus = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (currentStatus != 'Escalated')
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(
                                          () => currentStatus = 'Escalated');
                                    },
                                    icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 15,
                                        color: Colors.purple),
                                    label: const Text(
                                      'Chuyển cấp lên Phòng CTSV',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Notes TextField
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText:
                                    'Ghi chú can thiệp, biên bản hòa giải hoặc hướng dẫn hỗ trợ tâm lý...',
                                hintStyle: const TextStyle(fontSize: 12.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dialog Actions footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Đóng'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final caseNum = int.tryParse(item.id.replaceAll(RegExp(r'[^0-9]'), ''));
                            if (caseNum != null) {
                              await _caseService.updateCaseStatus(caseNum, currentStatus);
                            }
                            setState(() {
                              item.status = currentStatus;
                              item.interventionNotes = notesController.text;
                            });
                            Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Đã cập nhật trạng thái hồ sơ ${item.id} thành "$currentStatus" trên Database!'),
                                  backgroundColor: const Color(0xFF033877),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Lưu cập nhật can thiệp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF033877),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _xaiIndicator(String label, double score, double weight) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
          ),
        ),
        SizedBox(
          width: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                score > 0.8
                    ? const Color(0xFFEF4444)
                    : score > 0.5
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            score.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF033877),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

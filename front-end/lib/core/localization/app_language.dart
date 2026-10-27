import 'package:flutter/material.dart';
import '../../features/auth/domain/auth_models.dart';
import '../../features/dashboard/presentation/web_utils/web_utils.dart';

export '../../features/auth/domain/auth_models.dart' show AppLocale;

class AppLanguage {
  static final AppLanguage instance = AppLanguage._();

  AppLanguage._() {
    _initLocale();
  }

  late final ValueNotifier<AppLocale> localeNotifier;

  void _initLocale() {
    final saved = getSavedLocaleWeb();
    final initial = (saved == 'en') ? AppLocale.en : AppLocale.vi;
    localeNotifier = ValueNotifier<AppLocale>(initial);
  }

  AppLocale get currentLocale => localeNotifier.value;
  bool get isVietnamese => localeNotifier.value == AppLocale.vi;
  bool get isEnglish => localeNotifier.value == AppLocale.en;
  AppStrings get s => AppStrings(localeNotifier.value);

  void setLocale(AppLocale locale) {
    if (localeNotifier.value != locale) {
      localeNotifier.value = locale;
      saveLocaleWeb(locale == AppLocale.en ? 'en' : 'vi');
    }
  }

  void toggle() {
    setLocale(isVietnamese ? AppLocale.en : AppLocale.vi);
  }
}

class AppStrings {
  final AppLocale locale;
  const AppStrings(this.locale);

  bool get isVi => locale == AppLocale.vi;

  // ─── Header & Brand ──────────────────────────────────────────────────────────
  String get brandTitle => isVi ? 'AN TOÀN HỌC ĐƯỜNG' : 'CAMPUS SAFETY';
  String get brandSubtitle => isVi ? 'HỆ THỐNG GIÁM SÁT & BẢO VỆ' : 'SAFETY & VIOLATION DETECTOR';
  String get studentPortal => isVi ? 'CỔNG SINH VIÊN' : 'STUDENT PORTAL';
  String get teacherPortal => isVi ? 'CỔNG GIẢNG VIÊN' : 'TEACHER PORTAL';
  String get adminPortal => isVi ? 'CỔNG QUẢN TRỊ' : 'ADMIN PORTAL';
  String get currentLangName => isVi ? 'Tiếng Việt' : 'English';
  String get otherLangName => isVi ? 'English' : 'Tiếng Việt';
  String get flag => isVi ? '🇻🇳' : '🇬🇧';
  String get otherFlag => isVi ? '🇬🇧' : '🇻🇳';
  String get notifications => isVi ? 'Thông báo' : 'Notifications';
  String get logout => isVi ? 'Đăng xuất' : 'Sign Out';
  String get myAccount => isVi ? 'Tài khoản' : 'Account';
  String get adminDb => 'Admin DB';
  String get refresh => isVi ? 'Làm mới' : 'Refresh';

  // ─── Student Tabs ────────────────────────────────────────────────────────────
  String get studentTabReport => isVi ? 'Báo cáo vi phạm' : 'Report Incident';
  String get studentTabSos => isVi ? 'SOS Khẩn cấp' : 'Emergency SOS';
  String get studentTabHistory => isVi ? 'Lịch sử báo cáo' : 'Report History';
  String get studentTabChat => isVi ? 'Tư vấn & Chat' : 'Consultation';

  // ─── Teacher & Admin Tabs ────────────────────────────────────────────────────
  String get teacherTabOverview => isVi ? 'Tổng quan & Sự cố' : 'Overview & Cases';
  String get teacherTabCreate => isVi ? 'Ghi nhận vi phạm' : 'Record Incident';
  String get teacherTabSos => isVi ? 'Điều phối SOS' : 'SOS Dispatch';
  String get teacherTabHandled => isVi ? 'Hồ sơ đã xử lý' : 'Resolved Cases';
  String get teacherTabChat => isVi ? 'Kênh trao đổi' : 'Advisory Chat';

  // ─── Student Reporting Form ──────────────────────────────────────────────────
  String get reportHeader => isVi ? 'TIẾP NHẬN BÁO CÁO VI PHẠM HỌC ĐƯỜNG' : 'CAMPUS VIOLATION INCIDENT REPORT';
  String get reportSubHeader => isVi
      ? 'Hệ thống AI tiếp nhận phản ánh bạo lực, gian lận, quấy rối và các nguy cơ mất an toàn.'
      : 'AI-assisted system receiving reports on violence, cheating, harassment, and campus threats.';
  String get incidentTypeLabel => isVi ? 'Loại sự việc / hành vi vi phạm' : 'Incident Category';
  String get priorityLabel => isVi ? 'Mức độ ưu tiên / khẩn cấp' : 'Urgency / Priority Level';
  String get locationLabel => isVi ? 'Địa điểm xảy ra sự việc' : 'Incident Location';
  String get locationHint => isVi ? 'Ví dụ: Phòng 302, Tòa A, Sân bóng, Ký túc xá...' : 'e.g. Room 302, Hall A, Sports Ground, Dormitory...';
  String get descriptionLabel => isVi ? 'Mô tả chi tiết diễn biến sự việc' : 'Detailed Incident Description';
  String get descriptionHint => isVi
      ? 'Mô tả rõ thời gian, người liên quan, hành vi vi phạm và các thông tin cần can thiệp...'
      : 'Describe time, individuals involved, misconduct, and urgent interventions needed...';
  String get voiceToText => isVi ? 'Ghi lời nói (STT)' : 'Voice to Text';
  String get voiceListening => isVi ? 'Đang lắng nghe...' : 'Listening...';
  String get recordAudio => isVi ? 'Ghi âm sự việc' : 'Record Audio';
  String get stopRecording => isVi ? 'Dừng ghi âm' : 'Stop Recording';
  String get takePhoto => isVi ? 'Chụp ảnh' : 'Take Photo';
  String get attachFile => isVi ? 'Tải file đính kèm' : 'Attach Files';
  String get getGps => isVi ? 'Lấy vị trí GPS' : 'Get GPS Location';
  String get submitReportBtn => isVi ? 'Gửi báo cáo sự cố' : 'Submit Incident Report';
  String get anonymousOption => isVi ? 'Báo cáo ẩn danh (Bảo vệ danh tính cá nhân)' : 'Anonymous Report (Protect identity)';

  // ─── Emergency SOS ───────────────────────────────────────────────────────────
  String get sosHeader => isVi ? 'TRUNG TÂM PHÁT TÍN HIỆU CẦU CỨU KHẨN CẤP (SOS)' : 'EMERGENCY RESCUE BEACON (SOS)';
  String get sosSubHeader => isVi
      ? 'Nhấn nút SOS khi đang bị đe dọa trực tiếp, bạo lực thể xác, cướp giật hoặc nguy cơ khẩn cấp cần can thiệp tức thì!'
      : 'Press SOS in case of direct threats, physical violence, or extreme emergency needing immediate response!';
  String get sosButtonText => isVi ? 'GỬI TÍN HIỆU CẦU CỨU KHẨN CẤP (SOS)' : 'TRIGGER EMERGENCY SOS BEACON';
  String get sosSentSuccess => isVi ? 'Đã gửi tín hiệu cứu hộ khẩn cấp tới Ban Quản trị!' : 'Emergency SOS signal dispatched successfully!';

  // ─── Status & Priority Translators ───────────────────────────────────────────
  String status(String s) {
    final lower = s.toLowerCase().trim();
    if (lower == 'new' || lower == 'mới') return isVi ? 'Mới' : 'New';
    if (lower.contains('in progress') || lower.contains('đang')) return isVi ? 'Đang xử lý' : 'In Progress';
    if (lower.contains('resolved') || lower.contains('giải quyết')) return isVi ? 'Đã giải quyết' : 'Resolved';
    if (lower.contains('closed') || lower.contains('đóng')) return isVi ? 'Đã đóng' : 'Closed';
    return s;
  }

  String priority(String p) {
    final lower = p.toLowerCase().trim();
    if (lower == 'critical') return isVi ? 'Khẩn cấp' : 'Critical';
    if (lower == 'high') return isVi ? 'Cao' : 'High';
    if (lower == 'medium') return isVi ? 'Trung bình' : 'Medium';
    if (lower == 'low') return isVi ? 'Thấp' : 'Low';
    return p;
  }

  // ─── KPI & Dashboard ─────────────────────────────────────────────────────────
  String get kpiTotalCases => isVi ? 'Tổng số vụ việc' : 'Total Incidents';
  String get kpiSosCases => isVi ? 'Ca khẩn cấp (SOS)' : 'Emergency SOS';
  String get kpiInProgress => isVi ? 'Đang can thiệp' : 'In Progress';
  String get kpiResolved => isVi ? 'Đã giải quyết' : 'Resolved';
  String get searchHint => isVi ? 'Tìm kiếm vụ việc, người báo, địa điểm...' : 'Search cases, reporter, location...';
  String get filterAll => isVi ? 'Tất cả' : 'All';
  String get filterNew => isVi ? 'Mới' : 'New';
  String get filterInProgress => isVi ? 'Đang xử lý' : 'In Progress';
  String get filterResolved => isVi ? 'Đã xử lý' : 'Resolved';
  String get filterClosed => isVi ? 'Đã đóng' : 'Closed';

  // ─── Table Headers ───────────────────────────────────────────────────────────
  String get colId => isVi ? 'Mã' : 'ID';
  String get colIncident => isVi ? 'Hành vi vi phạm' : 'Incident Type';
  String get colReporter => isVi ? 'Người phản ánh' : 'Reporter';
  String get colLocation => isVi ? 'Địa điểm' : 'Location';
  String get colTime => isVi ? 'Thời gian' : 'Time';
  String get colPriority => isVi ? 'Ưu tiên' : 'Priority';
  String get colStatus => isVi ? 'Trạng thái' : 'Status';
  String get colRiskScore => isVi ? 'Rủi ro AI' : 'Risk Score';
  String get colActions => isVi ? 'Thao tác' : 'Actions';

  // ─── SOS Dispatch Panel ──────────────────────────────────────────────────────
  String get sosDispatchTitle => isVi ? 'TRUNG TÂM ĐIỀU PHỐI CỨU HỘ KHẨN CẤP (SOS)' : 'EMERGENCY RESCUE DISPATCH CENTER (SOS)';
  String sosDispatchSub(int count) => isVi
      ? 'CÁC TÍN HIỆU CẦU CỨU & NGUY CƠ KHẨN CẤP ($count vụ việc)'
      : 'EMERGENCY BEACONS & HIGH-RISK INCIDENTS ($count cases)';
  String get noSosTitle => isVi ? 'Hiện không có tín hiệu SOS hoặc nguy cơ khẩn cấp nào' : 'No emergency SOS signals at this time';
  String get noSosDesc => isVi
      ? 'Tất cả các ca khẩn cấp và nguy cơ cao đều đã được điều phối xử lý an toàn.'
      : 'All emergency signals and high-risk cases have been safely resolved.';

  // ─── Handled Cases Panel ─────────────────────────────────────────────────────
  String get handledCasesTitle => isVi ? 'HỒ SƠ VỤ VIỆC ĐÃ XỬ LÝ & LƯU TRỮ' : 'RESOLVED & ARCHIVED CASE RECORDS';
  String handledCasesSub(int count) => isVi
      ? 'DANH SÁCH HỒ SƠ ĐÃ HOÀN TẤT ($count vụ việc)'
      : 'COMPLETED CASE ARCHIVES ($count cases)';
  String get noHandledTitle => isVi ? 'Chưa có hồ sơ nào ở trạng thái hoàn tất lưu trữ' : 'No cases currently archived as resolved';
  String get noHandledDesc => isVi
      ? 'Các vụ việc sau khi can thiệp giải quyết hoặc đóng hồ sơ sẽ được lưu trữ tại đây.'
      : 'Cases will be archived here once interventions are resolved or closed.';
}

class LanguageSwitcherButton extends StatelessWidget {
  final bool compact;
  final Color? textColor;

  const LanguageSwitcherButton({
    super.key,
    this.compact = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocale>(
      valueListenable: AppLanguage.instance.localeNotifier,
      builder: (context, locale, _) {
        final isVi = locale == AppLocale.vi;

        return InkWell(
          onTap: () => AppLanguage.instance.toggle(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 6 : 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isVi ? '🇻🇳' : '🇬🇧',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  isVi ? 'VI' : 'EN',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: textColor ?? const Color(0xFF033877),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 14,
                  color: textColor ?? const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

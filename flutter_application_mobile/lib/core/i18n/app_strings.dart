import '../../features/auth/domain/auth_models.dart';

class AppDashboardStrings {
  const AppDashboardStrings(this.locale);
  final AppLocale locale;

  bool get isEn => locale == AppLocale.en;

  // Header & Navigation
  String get supportCenter => isEn ? 'UEL Support Center' : 'Trung tâm Hỗ trợ UEL';
  String get reportTab => isEn ? 'Report' : 'Báo cáo';
  String get sosTab => isEn ? 'Emergency SOS' : 'SOS Khẩn cấp';
  String get historyTab => isEn ? 'History' : 'Lịch sử';

  // Incident Form
  String get createReportTitle => isEn ? 'Report Violence / Violation' : 'Tạo Báo cáo Bạo lực / Vi phạm';
  String get incidentTypeLabel => isEn ? 'Violation Type' : 'Loại hình vi phạm';
  String get priorityLabel => isEn ? 'Priority Level' : 'Mức độ ưu tiên';
  String get locationLabel => isEn ? 'Location / Address' : 'Địa điểm / Vị trí';
  String get locationHint => isEn ? 'Enter or pick on map...' : 'Nhập hoặc chọn địa chỉ trên bản đồ...';
  String get descriptionLabel => isEn ? 'Detailed Description' : 'Mô tả chi tiết sự việc';
  String get descriptionHint => isEn ? 'Describe what happened...' : 'Mô tả cụ thể diễn biến, thời gian...';
  String get attachEvidence => isEn ? 'Attach Evidence (Image/Audio)' : 'Đính kèm Bằng chứng (Ảnh/Ghi âm)';
  String get submitReport => isEn ? 'Submit Report' : 'Gửi báo cáo';
  String get submitting => isEn ? 'Submitting...' : 'Đang gửi...';

  // SOS Screen Strings
  String get sosHeaderTitle => isEn ? 'Emergency SOS Defense' : 'Bảo vệ SOS Khẩn cấp';
  String get sosSubHeader => isEn ? 'Press button or shake phone 5 times' : 'Nhấn nút hoặc lắc điện thoại 5 lần';
  String get triggerSosButton => isEn ? 'TRIGGER EMERGENCY SOS' : 'KÍCH HOẠT SOS KHẨN CẤP';
  String get alarmOn => isEn ? 'SIREN ALARM: ON' : 'CÒI BÁO ĐỘNG: ĐANG BẬT';
  String get alarmOff => isEn ? 'SIREN ALARM: OFF' : 'CÒI BÁO ĐỘNG: TẮT';
  String get voiceListeningOn => isEn ? 'VOICE LISTENING: ACTIVE' : 'LẮNG NGHE GIỌNG NÓI: ĐANG BẬT';
  String get emergencyContacts => isEn ? 'Emergency Contacts' : 'Danh bạ Khẩn cấp';
  String get callSecurity => isEn ? 'Call Campus Security' : 'Gọi Bào vệ Trường';
  String get callHotline => isEn ? 'Call UEL Hotline' : 'Gọi Hotline UEL';
  String get callPolice => isEn ? 'Call Emergency Police (113)' : 'Gọi Công an 113';

  // Success / Error messages
  String get reportSubmittedSuccess => isEn ? 'Report submitted successfully!' : 'Đã gửi báo cáo thành công!';
  String get reportSubmitFailed => isEn ? 'Failed to submit report. Please check server connection.' : 'Gửi báo cáo thất bại. Vui lòng kiểm tra kết nối.';
}

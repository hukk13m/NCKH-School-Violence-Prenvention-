import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum SosPermissionKind {
  location,
  camera,
  microphone,
  contacts,
  sms,
  notification,
}

extension SosPermissionKindX on SosPermissionKind {
  Permission get permission => switch (this) {
    SosPermissionKind.location => Permission.locationWhenInUse,
    SosPermissionKind.camera => Permission.camera,
    SosPermissionKind.microphone => Permission.microphone,
    SosPermissionKind.contacts => Permission.contacts,
    SosPermissionKind.sms => Permission.sms,
    SosPermissionKind.notification => Permission.notification,
  };

  String get title => switch (this) {
    SosPermissionKind.location => 'Vị trí',
    SosPermissionKind.camera => 'Máy ảnh',
    SosPermissionKind.microphone => 'Micrô',
    SosPermissionKind.contacts => 'Danh bạ',
    SosPermissionKind.sms => 'SMS',
    SosPermissionKind.notification => 'Thông báo',
  };

  String get description => switch (this) {
    SosPermissionKind.location => 'Gửi vị trí hiện tại khi bạn cần trợ giúp',
    SosPermissionKind.camera => 'Chụp ảnh làm bằng chứng khi khẩn cấp',
    SosPermissionKind.microphone => 'Ghi âm âm thanh xung quanh',
    SosPermissionKind.contacts => 'Chọn người thân nhận tin nhắn khẩn cấp',
    SosPermissionKind.sms => 'Gửi tin nhắn khẩn cấp đến người thân',
    SosPermissionKind.notification => 'Nhận thông báo về báo cáo SOS',
  };

  IconData get icon => switch (this) {
    SosPermissionKind.location => Icons.location_on_rounded,
    SosPermissionKind.camera => Icons.photo_camera_rounded,
    SosPermissionKind.microphone => Icons.mic_rounded,
    SosPermissionKind.contacts => Icons.contacts_rounded,
    SosPermissionKind.sms => Icons.sms_rounded,
    SosPermissionKind.notification => Icons.notifications_rounded,
  };
}

/// Các quyền hiển thị trong màn hình giới thiệu lần đầu.
const List<SosPermissionKind> sosIntroPermissions = [
  SosPermissionKind.contacts,
  SosPermissionKind.sms,
  SosPermissionKind.location,
  SosPermissionKind.microphone,
  SosPermissionKind.notification,
  SosPermissionKind.camera,
];

/// Các quyền hiển thị trong bảng "Quyền truy cập của hệ thống".
const List<SosPermissionKind> sosSettingPermissions = [
  SosPermissionKind.location,
  SosPermissionKind.camera,
  SosPermissionKind.microphone,
  SosPermissionKind.contacts,
  SosPermissionKind.sms,
];

class SosPermissionService {
  Future<PermissionStatus> statusOf(SosPermissionKind kind) {
    return kind.permission.status;
  }

  Future<PermissionStatus> request(SosPermissionKind kind) async {
    final current = await kind.permission.status;
    if (current.isGranted || current.isLimited) return current;
    return kind.permission.request();
  }

  Future<void> requestIntroPermissions() async {
    for (final kind in sosIntroPermissions) {
      try {
        await request(kind);
      } catch (_) {
        // Một số nền tảng không hỗ trợ quyền (ví dụ SMS trên iOS).
      }
    }
  }

  Future<bool> openSettings() => openAppSettings();
}

import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình người dùng cho tính năng SOS.
///
/// Hai trường [contactPhone] và [emergencyMessage] hiện được để trống theo
/// yêu cầu. Khi nhà trường cung cấp số điện thoại, chỉ cần nhập vào màn hình
/// "Chia sẻ ngoại tuyến"; không cần sửa code.
class SosSettings {
  const SosSettings({
    this.offlineEnabled = false,
    this.contactPhone = '',
    this.emergencyMessage = '',
  });

  final bool offlineEnabled;
  final String contactPhone;
  final String emergencyMessage;

  SosSettings copyWith({
    bool? offlineEnabled,
    String? contactPhone,
    String? emergencyMessage,
  }) {
    return SosSettings(
      offlineEnabled: offlineEnabled ?? this.offlineEnabled,
      contactPhone: contactPhone ?? this.contactPhone,
      emergencyMessage: emergencyMessage ?? this.emergencyMessage,
    );
  }
}

/// Lưu các thiết lập SOS cục bộ bằng SharedPreferences.
class SosSettingsStore {
  static const _seenPermissionIntroKey = 'sos_permission_intro_seen_v1';
  static const _offlineEnabledKey = 'sos_offline_enabled_v1';
  static const _contactPhoneKey = 'sos_contact_phone_v1';
  static const _emergencyMessageKey = 'sos_emergency_message_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> hasSeenPermissionIntro() async {
    final prefs = await _prefs;
    return prefs.getBool(_seenPermissionIntroKey) ?? false;
  }

  Future<void> markPermissionIntroSeen() async {
    final prefs = await _prefs;
    await prefs.setBool(_seenPermissionIntroKey, true);
  }

  Future<SosSettings> load() async {
    final prefs = await _prefs;
    return SosSettings(
      offlineEnabled: prefs.getBool(_offlineEnabledKey) ?? false,
      contactPhone: prefs.getString(_contactPhoneKey) ?? '',
      emergencyMessage: prefs.getString(_emergencyMessageKey) ?? '',
    );
  }

  Future<void> save(SosSettings settings) async {
    final prefs = await _prefs;
    await prefs.setBool(_offlineEnabledKey, settings.offlineEnabled);
    await prefs.setString(_contactPhoneKey, settings.contactPhone.trim());
    await prefs.setString(
      _emergencyMessageKey,
      settings.emergencyMessage.trim(),
    );
  }
}

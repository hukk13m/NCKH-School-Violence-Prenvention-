import 'package:flutter/material.dart';
import '../../../../core/localization/app_language.dart';

class AccountProfileDialog extends StatelessWidget {
  final String userFullName;
  final String userEmail;
  final String userIdCode;
  final String userDepartment;
  final String userRole;
  final VoidCallback onLogout;

  const AccountProfileDialog({
    super.key,
    required this.userFullName,
    required this.userEmail,
    required this.userIdCode,
    required this.userDepartment,
    required this.userRole,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLanguage.instance.s;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header profile
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF0A3878).withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF0A3878),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userFullName.isNotEmpty ? userFullName : 'Người dùng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A3878),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85D26).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            userRole,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE85D26),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              Text(
                s.isVi ? 'Thông tin cá nhân xác thực' : 'Verified Profile Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A3878),
                ),
              ),
              const SizedBox(height: 14),

              // Read-only User Details
              _buildInfoRow(Icons.person_outline_rounded, s.isVi ? 'Họ và tên' : 'Full Name', userFullName),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.email_outlined, s.isVi ? 'Email liên hệ' : 'Contact Email', userEmail),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.badge_outlined, s.isVi ? 'Mã định danh (MSSV/CB)' : 'ID Code', userIdCode),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.school_outlined, s.isVi ? 'Đơn vị / Khoa' : 'Faculty / Department', userDepartment),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3878).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: Color(0xFF0A3878),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.isVi ? 'Ngôn ngữ hiển thị' : 'Display Language',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const LanguageSwitcherButton(compact: true),
                ],
              ),

              const SizedBox(height: 26),

              // Safe Logout Button Only
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(s.isVi ? 'Đăng xuất tài khoản' : 'Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0A3878)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : '---',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

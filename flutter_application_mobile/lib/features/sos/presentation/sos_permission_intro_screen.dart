import 'package:flutter/material.dart';

import '../domain/sos_permissions.dart';

/// Màn hình giới thiệu quyền, chỉ hiển thị ở lần đầu người dùng mở SOS.
class SosPermissionIntroScreen extends StatefulWidget {
  const SosPermissionIntroScreen({super.key, required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  State<SosPermissionIntroScreen> createState() =>
      _SosPermissionIntroScreenState();
}

class _SosPermissionIntroScreenState extends State<SosPermissionIntroScreen> {
  final SosPermissionService _permissionService = SosPermissionService();
  bool _requesting = false;

  Future<void> _continue() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    await _permissionService.requestIntroPermissions();
    await widget.onContinue();
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3B7A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SOS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFF0B6EDB),
                      size: 46,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SOS cần có những quyền sau:',
                      style: TextStyle(
                        color: Color(0xFF0A2F5D),
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Các quyền này giúp hệ thống gửi vị trí, bằng chứng và '
                      'thông tin khẩn cấp nhanh nhất có thể.',
                      style: TextStyle(
                        color: Color(0xFF53709F),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < sosIntroPermissions.length; i++)
                            _PermissionRow(
                              kind: sosIntroPermissions[i],
                              showDivider: i != sosIntroPermissions.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _requesting ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6EDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.kind, required this.showDivider});

  final SosPermissionKind kind;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6EDB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(kind.icon, color: const Color(0xFF0B6EDB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.title,
                      style: const TextStyle(
                        color: Color(0xFF0A2F5D),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kind.description,
                      style: const TextStyle(
                        color: Color(0xFF6683AA),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE9F1FC)),
      ],
    );
  }
}

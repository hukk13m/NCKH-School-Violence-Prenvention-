import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/sos_permissions.dart';

Future<void> showSosPermissionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SosPermissionSheet(),
  );
}

class _SosPermissionSheet extends StatefulWidget {
  const _SosPermissionSheet();

  @override
  State<_SosPermissionSheet> createState() => _SosPermissionSheetState();
}

class _SosPermissionSheetState extends State<_SosPermissionSheet>
    with WidgetsBindingObserver {
  final SosPermissionService _permissionService = SosPermissionService();
  final Map<SosPermissionKind, PermissionStatus> _statuses = {};
  final Set<SosPermissionKind> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatuses();
    }
  }

  Future<void> _loadStatuses() async {
    for (final kind in sosSettingPermissions) {
      try {
        final status = await _permissionService.statusOf(kind);
        if (!mounted) return;
        setState(() => _statuses[kind] = status);
      } catch (_) {
        // Bỏ qua quyền không được hỗ trợ trên nền tảng hiện tại.
      }
    }
  }

  bool _isOn(SosPermissionKind kind) {
    final status = _statuses[kind];
    return status?.isGranted == true || status?.isLimited == true;
  }

  Future<void> _toggle(SosPermissionKind kind, bool value) async {
    if (_busy.contains(kind)) return;
    setState(() => _busy.add(kind));
    try {
      var status = await _permissionService.statusOf(kind);
      if (value) {
        status = await _permissionService.request(kind);
        if (status.isPermanentlyDenied || status.isRestricted) {
          await _permissionService.openSettings();
          status = await _permissionService.statusOf(kind);
        }
      } else {
        await _permissionService.openSettings();
        status = await _permissionService.statusOf(kind);
      }
      if (!mounted) return;
      setState(() => _statuses[kind] = status);
      if (!value && _isOn(kind)) {
        _showMessage(
          'Hãy tắt quyền ${kind.title} trong phần Cài đặt của thiết bị.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể thay đổi quyền ${kind.title}.');
      }
    } finally {
      if (mounted) setState(() => _busy.remove(kind));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5E3F7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUYỀN TRUY CẬP CỦA HỆ THỐNG',
                    style: TextStyle(
                      color: Color(0xFF0A2F5D),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Bật các quyền cần thiết để SOS hoạt động hiệu quả nhất.',
                    style: TextStyle(
                      color: Color(0xFF6683AA),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final kind in sosSettingPermissions)
                      _PermissionSwitchRow(
                        kind: kind,
                        value: _isOn(kind),
                        busy: _busy.contains(kind),
                        onChanged: (value) => _toggle(kind, value),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 22, 2),
              child: Text(
                'Bạn có thể thay đổi các quyền này bất cứ lúc nào trong phần '
                'Cài đặt của thiết bị.',
                style: TextStyle(
                  color: Color(0xFF8AA5C7),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionSwitchRow extends StatelessWidget {
  const _PermissionSwitchRow({
    required this.kind,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final SosPermissionKind kind;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EFFB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0B6EDB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(kind.icon, color: const Color(0xFF0B6EDB), size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.title,
                  style: const TextStyle(
                    color: Color(0xFF0A2F5D),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kind.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718CB0),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch.adaptive(
              value: value,
              activeTrackColor: const Color(0xFF0B6EDB),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

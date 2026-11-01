import 'package:flutter/material.dart';

import '../data/sos_settings_store.dart';
import 'sos_permission_intro_screen.dart';
import 'sos_screen.dart';

/// Điểm vào tính năng SOS.
///
/// Lần đầu tiên sẽ hiển thị màn hình xin quyền; các lần sau đi thẳng vào màn
/// hình SOS chính.
class SosEntryScreen extends StatefulWidget {
  const SosEntryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<SosEntryScreen> createState() => _SosEntryScreenState();
}

class _SosEntryScreenState extends State<SosEntryScreen> {
  final SosSettingsStore _settingsStore = SosSettingsStore();
  bool _loading = true;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await _settingsStore.hasSeenPermissionIntro();
    if (!mounted) return;
    setState(() {
      _showIntro = !seen;
      _loading = false;
    });
  }

  Future<void> _completeIntro() async {
    await _settingsStore.markPermissionIntroSeen();
    if (!mounted) return;
    setState(() => _showIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F9FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_showIntro) {
      return SosPermissionIntroScreen(onContinue: _completeIntro);
    }
    return SosScreen(userId: widget.userId, userName: widget.userName);
  }
}

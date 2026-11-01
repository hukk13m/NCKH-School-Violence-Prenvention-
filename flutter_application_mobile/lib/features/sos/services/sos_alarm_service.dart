import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Phát âm thanh SOS lặp lại và rung theo nhịp cho đến khi người dùng dừng.
class SosAlarmService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _vibrationTimer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1);
      await _player.play(AssetSource('audio/sos_alert.mp3'));
    } catch (_) {
      // Nếu thiết bị không phát được âm thanh, vẫn tiếp tục rung và gửi báo cáo.
    }

    _vibrateOnce();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _vibrateOnce();
    });
  }

  Future<void> _vibrateOnce() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;
      await Vibration.vibrate(pattern: [0, 700, 350, 700]);
    } catch (_) {
      // Một số thiết bị/trình duyệt không hỗ trợ rung.
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await _player.stop();
    } catch (_) {
      // Bỏ qua lỗi dừng âm thanh.
    }
    try {
      await Vibration.cancel();
    } catch (_) {
      // Bỏ qua lỗi hủy rung.
    }
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}

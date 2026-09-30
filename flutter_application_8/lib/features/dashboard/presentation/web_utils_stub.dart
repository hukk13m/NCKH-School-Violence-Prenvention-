import 'dart:typed_data';

// Stub implementations cho non-web platforms
void downloadFileWeb(String? blobUrl, String filename) {
  // No-op on non-web
}

void captureImageWeb(void Function(String name, int size, Uint8List? bytes) onFile) {
  // No-op on non-web
}

Future<bool> startAudioRecordingWeb(
    void Function(String name, String blobUrl) onDone) async {
  return false; // not supported
}

void stopAudioRecordingWeb() {
  // No-op on non-web
}

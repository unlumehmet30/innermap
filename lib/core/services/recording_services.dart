// lib/core/services/recording_service.dart

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  // 1. Mikrofon İzinlerini Kontrol Etme
  Future<bool> checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  // 2. Kaydı Başlatma
  Future<String?> startRecording() async {
    if (await checkPermission()) {
      try {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(encoder: AudioEncoder.aacLc);

        await _audioRecorder.start(config, path: filePath);

        print('Kayıt Başladı: $filePath');
        return filePath;
      } catch (e) {
        print('Kayıt Başlatma Hatası: $e');
        return null;
      }
    } else {
      print('Mikrofon izni reddedildi.');
      return null;
    }
  }

  // 3. Kaydı Durdurma
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      print('Kayıt Durduruldu. Dosya Yolu: $path');
      return path;
    } catch (e) {
      print('Kayıt Durdurma Hatası: $e');
      return null;
    }
  }

  // 4. Kayıt Durumunu Kontrol Etme
  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }
}
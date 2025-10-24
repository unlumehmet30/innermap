// lib/core/services/http_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innermap/core/constant/api_constants.dart'; // PAKET YOLU DÜZELTİLDİ

class HttpService {
  // Ses dosyasını backend'e gönderir ve metin transkripsiyonunu alır.
  Future<Map<String, dynamic>?> uploadAudioForTranscription(
    String filePath,
  ) async {
    final uri = Uri.parse('$kBaseUrl$kTranscribeEndpoint');

    try {
      // 1. Multipart Request Oluşturma
      var request = http.MultipartRequest('POST', uri);

      // 2. Ses Dosyasını Ekleme
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Backend'in beklediği parametre adı
          filePath,
        ),
      );

      // 3. İsteği Gönderme
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 4. Yanıtı Kontrol Etme
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print(
          'Backend Yanıt Hatası (${response.statusCode}): ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('HTTP İletişim Hatası: $e');
      return null;
    }
  }

  // 1. Haftanın diğer bir ihtiyacı: Metin girdisini göndermek.
  Future<Map<String, dynamic>?> sendTextForAnalysis(String text) async {
    // Backend'de bu uç noktayı tanımlamanız gerekecektir
    final uri = Uri.parse('$kBaseUrl/analyze_text'); 

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Text Analiz Hatası (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Text Gönderme Hatası: $e');
      return null;
    }
  }
}

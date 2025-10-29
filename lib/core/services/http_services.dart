// lib/core/services/http_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innermap/core/constant/api_constants.dart';

class HttpService {
  // Ses dosyasını backend'e gönderir ve metin transkripsiyonunu alır.
  // Not: Şimdilik transkripsiyon metnini döndürüyoruz. İleride (Daha sonraki görev)
  // bu metni LLM analizine göndermek için bu fonksiyon güncellenecektir.
  Future<Map<String, dynamic>?> uploadAudioForTranscription(
    String filePath,
  ) async {
    final uri = Uri.parse('$kBaseUrl$kTranscribeEndpoint');

    try {
      var request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Backend'in beklediği parametre adı
          filePath,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

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

  // 🚨 GÜNCELLENDİ: LLM'den gelen Node/Edge verilerini içeren 'data' alanını döndürür.
  Future<Map<String, dynamic>?> sendTextForAnalysis(String text) async {
    final uri = Uri.parse('$kBaseUrl/analyze_text'); 

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        
        // LLM'den gelen 'data' alanını kontrol et ve döndür
        if (jsonResponse.containsKey('data')) {
          // 'data', ConceptNode ve ConceptEdge listelerini içeren Map'tir.
          return jsonResponse['data'] as Map<String, dynamic>; 
        } else {
          print('LLM Analiz Hatası: Yanıt "data" alanı içermiyor.');
          return null;
        }
      } else {
        print('LLM Analiz Hatası (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Text Gönderme Hatası: $e');
      return null;
    }
  }
}
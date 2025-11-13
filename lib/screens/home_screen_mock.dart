// lib/screens/home_screen_mock.dart

import 'package:flutter/material.dart';
import 'package:innermap/core/services/recording_services.dart';
import 'package:innermap/core/constant/mock_data.dart';
// import 'package:innermap/core/services/http_service.dart'; // LLM/HTTP Servisi atlanıyor

// HomeScreen'in Harita verisini dışarı aktarabilmesi için Callback tanımlanır
typedef OnAnalysisComplete = void Function(Map<String, dynamic> data);

class HomeScreenMock extends StatefulWidget {
  final OnAnalysisComplete onAnalysisComplete;

  const HomeScreenMock({
    super.key,
    required this.onAnalysisComplete,
  });

  @override
  State<HomeScreenMock> createState() => _HomeScreenMockState();
}

class _HomeScreenMockState extends State<HomeScreenMock> {
  final RecordingService _recordingService = RecordingService();
  final TextEditingController _textController = TextEditingController();

  // --- Durum Yönetimi ---
  bool _isRecording = false; 
  bool _isProcessing = false; 
  String _recognizedText =
      "Lütfen fikrinizi sesli veya yazılı olarak paylaşın (Simülasyon Aktif)..."; 

  // 1. Ses Kaydını Başlat/Durdur
  void _toggleRecording() async {
    if (_isProcessing) return; 

    if (!_isRecording) {
      // KAYDI BAŞLAT
      final filePath = await _recordingService.startRecording();
      
      setState(() {
        _isRecording = true;
        _recognizedText = filePath != null ? "Dinliyorum... Konuşun (MOCK)..." : "Hata.";
      });

    } else {
      // KAYDI DURDUR ve SİMÜLASYON YAP
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _recognizedText = "Ses kaydı tamamlandı. LLM Simülasyonu başlatılıyor...";
      });

      await _recordingService.stopRecording();
      await Future.delayed(const Duration(seconds: 1)); 

      // 🚨 KRİTİK: Haritaya YÖNLENDİRMEK YERİNE CALLBACK ÇAĞIR
      widget.onAnalysisComplete(mockMapData);

      setState(() {
        _isProcessing = false;
        _recognizedText = "Analiz tamamlandı. Haritayı görmek için Alt Menüden Harita'yı seçin.";
      });
      
    }
  }

  // 2. Metin Girişini Onayla (MOCK AKIŞI)
  void _processText(String text) async {
    if (text.trim().isEmpty || _isRecording || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = "Yazılı metin alındı. LLM Simülasyonu başlatılıyor...";
    });

    await Future.delayed(const Duration(milliseconds: 500)); 

    // 🚨 KRİTİK: Haritaya YÖNLENDİRMEK YERİNE CALLBACK ÇAĞIR
    widget.onAnalysisComplete(mockMapData);

    setState(() {
      _isProcessing = false;
      _recognizedText = "Analiz tamamlandı. Haritayı görmek için Alt Menüden Harita'yı seçin.";
    });
    
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Map MVP - Fikir Girişi (MOCK)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metin Girdi Alanı 
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Fikrinizi buraya yazın (MOCK Testi)...',
                suffixIcon: IconButton(
                  // Bu tuş artık sadece LLM'e gönderme işini yapar
                  icon: const Icon(Icons.send), 
                  onPressed: () => _processText(_textController.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _processText,
              enabled: !_isProcessing && !_isRecording, 
            ),
            // ... (Diğer UI elemanları)
             const SizedBox(height: 24),

            const Text(
              "Sistem Durumu/Geri Bildirim:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Çözümlenmiş Metin/Geri Bildirim Alanı
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _isProcessing ? 'İşleniyor...' : _recognizedText,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Ses Kayıt Butonu
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton.extended(
          onPressed: _toggleRecording,
          backgroundColor: _isProcessing 
              ? Colors.grey 
              : (_isRecording ? Colors.red.shade600 : Colors.blue.shade600),
          foregroundColor: Colors.white,

          label: Text(_isProcessing 
              ? "İşleniyor..."
              : (_isRecording ? "Kaydı Durdur" : "Konuşmaya Başla")),
          icon: Icon(_isProcessing 
              ? Icons.hourglass_top 
              : (_isRecording ? Icons.stop : Icons.mic)),
        ),
      ),
      // Alt Navigasyon Çubuğu BU EKRANDA OLMAYACAK (NavigationShell'de)
      // bottomNavigationBar kaldırıldı.
    );
  }
}
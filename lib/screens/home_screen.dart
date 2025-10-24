import 'package:flutter/material.dart';

// PAKET YOLLARI DÜZELTİLDİ
import 'package:innermap/core/services/recording_services.dart';
import 'package:innermap/core/services/http_services.dart'; 


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servis örnekleri
  final RecordingService _recordingService = RecordingService();
  final HttpService _httpService = HttpService();
  
  // Metin girişi için Controller
  final TextEditingController _textController = TextEditingController();

  // --- Durum Yönetimi ---
  bool _isRecording = false; // Kayıt durumu
  bool _isProcessing = false; // İşlemde olma durumu (backend bekleniyor)
  String _recognizedText =
      "Lütfen fikrinizi sesli veya yazılı olarak paylaşın..."; 

  // 1. Ses Kaydını Başlat/Durdur
  void _toggleRecording() async {
    if (_isProcessing) return; 

    if (!_isRecording) {
      // KAYDI BAŞLAT
      final hasPermission = await _recordingService.checkPermission();
      if (!hasPermission) {
        setState(() {
          _recognizedText = "Hata: Mikrofon izni gereklidir.";
        });
        return;
      }
      
      final filePath = await _recordingService.startRecording();
      
      setState(() {
        _isRecording = true;
        _recognizedText = filePath != null
            ? "Dinliyorum... Konuşun."
            : "Kayıt başlatılamadı.";
      });

    } else {
      // KAYDI DURDUR, GÖNDER VE ANALİZ ET
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _recognizedText = "Ses kaydı tamamlandı. Metin analiz ediliyor...";
      });

      final filePath = await _recordingService.stopRecording();
      
      if (filePath != null) {
        // Backend'e Gönderme
        final response = await _httpService.uploadAudioForTranscription(filePath);

        setState(() {
          _isProcessing = false;
          // Backend'den gelen anahtar 'transcript' olmalı
          _recognizedText = response != null && response.containsKey('transcript')
              ? response['transcript'] 
              : "Analiz tamamlandı, ancak backend'den geçerli bir metin gelmedi. (Kontrol edin)";
        });

      } else {
        setState(() {
          _isProcessing = false;
          _recognizedText = "Kayıt dosyası oluşturulamadı veya bulunamadı.";
        });
      }
    }
  }

  // 2. Metin Girişini Onayla (Yazılı Giriş)
  void _processText(String text) async {
    if (text.trim().isEmpty || _isRecording || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = "Yazılı metin alındı. Analiz ediliyor...";
    });

    final response = await _httpService.sendTextForAnalysis(text);

    setState(() {
      _isProcessing = false;
      _textController.clear();
      
      // Varsayım: Metin analizinde 'analysis' anahtarı dönecek
      _recognizedText = response != null && response.containsKey('analysis')
          ? response['analysis']
          : "Yazılı metin analizi tamamlandı. (Backend'de /analyze_text uç noktasını tanımlayın)";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Innermap - Fikir Girişi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metin Girdi Alanı (Yazılı Giriş)
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Fikrinizi buraya yazın...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _processText(_textController.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _processText,
              enabled: !_isProcessing && !_isRecording, 
            ),

            const SizedBox(height: 24),

            const Text(
              "Yapay Zeka Analizi:",
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

      // Ses Kayıt Butonu (Floating Action Button)
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

      // Alt Navigasyon Çubuğu (1. Hafta Gerekliliği)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Giriş'),
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Geçmiş'),
        ],
        onTap: (index) {
          // Sayfa Yönlendirmeleri buraya gelecek
        },
      ),
    );
  }
}
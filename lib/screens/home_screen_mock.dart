import 'package:flutter/material.dart';
import 'package:innermap/core/services/recording_services.dart';
// import 'package:innermap/core/services/http_service.dart'; // LLM/HTTP Servisi atlanıyor
import 'package:innermap/core/constant/mock_data.dart'; // Mock veri eklendi
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';
import 'package:innermap/screens/map_screen.dart'; 


class HomeScreenMock extends StatefulWidget {
  // Projenizdeki gerçek HomeScreen'den ayırt etmek için adını Mock olarak değiştirdik
  const HomeScreenMock({super.key});

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

  // --- Yardımcı Fonksiyon: Veriyi Çözümle ve Harita Ekranına Yönlendir ---
  void _navigateToMap(Map<String, dynamic> data) {
    
    // JSON listelerini Dart modellerine çevir
    final List<ConceptNode> nodes = (data['nodes'] as List)
        .map((item) => ConceptNode.fromJson(item as Map<String, dynamic>))
        .toList();
    
    final List<ConceptEdge> edges = (data['edges'] as List)
        .map((item) => ConceptEdge.fromJson(item as Map<String, dynamic>))
        .toList();

    // Harita ekranına yönlendir ve veriyi gönder
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(nodes: nodes, edges: edges),
      ),
    );
    
    // Yönlendirme sonrası ekran durumunu sıfırla
    setState(() {
      _isProcessing = false;
      _recognizedText = "Simülasyon tamamlandı. Sonuç Harita ekranında.";
    });
  }


  // 1. Ses Kaydını Başlat/Durdur (MOCK AKIŞI)
  void _toggleRecording() async {
    if (_isProcessing) return; 

    if (!_isRecording) {
      // KAYDI BAŞLAT
      // ... (İzin kontrolü ve kayıt başlatma mantığı)
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

      // Kayıt durdurulur
      await _recordingService.stopRecording();
      
      // Simülasyon bekleme süresi
      await Future.delayed(const Duration(seconds: 1)); 

      // 🚨 KRİTİK: Sabit Mock verisi ile Harita ekranına yönlendir
      _navigateToMap(mockMapData); 
      
    }
  }

  // 2. Metin Girişini Onayla (MOCK AKIŞI)
  void _processText(String text) async {
    if (text.trim().isEmpty || _isRecording || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = "Yazılı metin alındı. LLM Simülasyonu başlatılıyor...";
    });

    // Simülasyon bekleme süresi
    await Future.delayed(const Duration(milliseconds: 500)); 

    // 🚨 KRİTİK: Sabit Mock verisi ile Harita ekranına yönlendir
    _navigateToMap(mockMapData); 
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
              : (_isRecording ? "Kaydı Durdur" : "Konuşmaya Başla (MOCK)")),
          icon: Icon(_isProcessing 
              ? Icons.hourglass_top 
              : (_isRecording ? Icons.stop : Icons.mic)),
        ),
      ),

      // Alt Navigasyon Çubuğu

    );
  }
}
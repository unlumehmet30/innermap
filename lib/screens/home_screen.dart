import 'package:flutter/material.dart';
import 'package:innermap/core/services/recording_services.dart';
import 'package:innermap/core/services/http_services.dart';
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';
import 'package:innermap/screens/map_screen.dart'; // Navigasyon için eklendi


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecordingService _recordingService = RecordingService();
  final HttpService _httpService = HttpService();
  final TextEditingController _textController = TextEditingController();

  // --- Durum Yönetimi ---
  bool _isRecording = false; 
  bool _isProcessing = false; 
  String _recognizedText =
      "Lütfen fikrinizi sesli veya yazılı olarak paylaşın..."; 

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
      _recognizedText = "Analiz tamamlandı. Sonuç Harita ekranında.";
    });
  }


  // 1. Ses Kaydını Başlat/Durdur
  void _toggleRecording() async {
    if (_isProcessing) return; 

    if (!_isRecording) {
      // KAYDI BAŞLAT
      // ... (Kayıt başlatma mantığı aynı kalır)
      final hasPermission = await _recordingService.checkPermission();
      if (!hasPermission) {
        setState(() { _recognizedText = "Hata: Mikrofon izni gereklidir."; });
        return;
      }
      
      final filePath = await _recordingService.startRecording();
      
      setState(() {
        _isRecording = true;
        _recognizedText = filePath != null ? "Dinliyorum... Konuşun." : "Kayıt başlatılamadı.";
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
        // Backend'e Gönderme (Şimdilik Transkripsiyon Alınıyor)
        final transcriptionResponse = await _httpService.uploadAudioForTranscription(filePath);
        
        // 🚨 YENİ MANTIK: Transkripsiyon metnini LLM'e gönderme
        if (transcriptionResponse != null && transcriptionResponse.containsKey('transcript')) {
            final transcript = transcriptionResponse['transcript'] as String;
            
            // LLM analizini başlat
            final llmAnalysisData = await _httpService.sendTextForAnalysis(transcript);

            if (llmAnalysisData != null) {
                // Başarılı: Harita ekranına yönlendir
                _navigateToMap(llmAnalysisData);
            } else {
                // LLM'den hata geldi
                setState(() {
                    _isProcessing = false;
                    _recognizedText = "Hata: LLM Analizi başarısız oldu.";
                });
            }

        } else {
            // Transkripsiyon hatası
            setState(() {
                _isProcessing = false;
                _recognizedText = "Kayıt veya Transkripsiyon hatası.";
            });
        }
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

    final llmAnalysisData = await _httpService.sendTextForAnalysis(text);

    if (llmAnalysisData != null) {
        _navigateToMap(llmAnalysisData);
        _textController.clear();
    } else {
        setState(() {
            _isProcessing = false;
            _recognizedText = "Hata: LLM Analizi başarısız oldu.";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Map MVP - Fikir Girişi'),
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
              : (_isRecording ? "Kaydı Durdur" : "Konuşmaya Başla")),
          icon: Icon(_isProcessing 
              ? Icons.hourglass_top 
              : (_isRecording ? Icons.stop : Icons.mic)),
        ),
      ),

      // Alt Navigasyon Çubuğu
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Giriş'),
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Geçmiş'),
        ],
        onTap: (index) {
          // İleride Sayfa Yönlendirmeleri Buraya Gelecek
        },
      ),
    );
  }
}
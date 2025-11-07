// lib/core/constants/mock_data.dart

/// LLM'den gelmesi beklenen JSON çıktısını simüle eden veridir.
/// Sadece 3. Hafta testleri için kullanılır.

const Map<String, dynamic> mockMapData = {
  "nodes": [
    {"id": "N1", "text": "Innermap Projesi", "type": "Topic"},
    {"id": "N2", "text": "1. Hafta (Mimari)", "type": "SubIdea"},
    {"id": "N3", "text": "2. Hafta (LLM Entegrasyonu)", "type": "SubIdea"},
    {"id": "N4", "text": "3. Hafta (Görselleştirme)", "type": "SubIdea"},
    {"id": "N5", "text": "Gelecek (Kaydetme)", "type": "Action"},
  ],
  "edges": [
    {"id": "E1", "sourceId": "N1", "targetId": "N2", "label": "İçerir"},
    {"id": "E2", "sourceId": "N1", "targetId": "N3", "label": "İçerir"},
    {"id": "E3", "sourceId": "N1", "targetId": "N4", "label": "İçerir"},
    {"id": "E4", "sourceId": "N4", "targetId": "N5", "label": "Hedefler"}
  ]
};
// lib/models/map_entry.dart

class MapEntry {
  final String id;          // Haritanın benzersiz ID'si (Kaydetmek için anahtar)
  final String title;       // Kullanıcının veya AI'ın verdiği başlık
  final DateTime timestamp;  // Ne zaman kaydedildiği
  final String jsonData;    // ConceptNode ve Edge listesini içeren JSON stringi

  MapEntry({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.jsonData,
  });

  // Kayıtlı JSON'dan (shared_preferences) MapEntry objesi oluşturma
  factory MapEntry.fromJson(Map<String, dynamic> json) {
    return MapEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      jsonData: json['jsonData'] as String,
    );
  }

  // MapEntry objesini shared_preferences'a kaydetmek için JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'jsonData': jsonData,
    };
  }
}
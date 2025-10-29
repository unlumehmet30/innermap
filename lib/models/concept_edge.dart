// lib/models/concept_edge.dart

class ConceptEdge {
  final String id;          // Bağlantının benzersiz kimliği (Örn: "E1")
  final String sourceId;    // Başlangıç düğümünün ID'si (Örn: "N1")
  final String targetId;    // Bitiş düğümünün ID'si (Örn: "N2")
  final String? label;      // Bağlantı üzerindeki açıklama (Örn: "Nedenidir")
  
  ConceptEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.label,
  });

  // JSON'dan Dart objesine çevirme
  factory ConceptEdge.fromJson(Map<String, dynamic> json) {
    return ConceptEdge(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      label: json['label'] as String?,
    );
  }

  // Dart objesini JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'targetId': targetId,
      'label': label,
    };
  }
}
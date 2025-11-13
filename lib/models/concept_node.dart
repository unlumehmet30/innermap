// lib/models/concept_node.dart

class ConceptNode {
  final String id;
  final String text;
  final String type;
  final double? x;
  final double? y;

  ConceptNode({
    required this.id,
    required this.text,
    required this.type,
    this.x,
    this.y,
  });

  // 🚨 YENİ METOT: Modeli güncelleyip yeni bir nesne oluşturur (Immutability)
  ConceptNode copyWith({
    String? id,
    String? text,
    String? type,
    double? x,
    double? y,
  }) {
    return ConceptNode(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  // LLM'den gelecek JSON verisini Dart objesine çevirme
  factory ConceptNode.fromJson(Map<String, dynamic> json) {
    return ConceptNode(
      id: json['id'] as String,
      text: json['text'] as String,
      type: json['type'] as String,
      // JSON'dan gelen x/y değerlerini güvenle double'a çevir
      x: (json['x'] as num?)?.toDouble(), 
      y: (json['y'] as num?)?.toDouble(),
    );
  }

  // Dart objesini LLM'e göndermek veya kaydetmek için JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'x': x,
      'y': y,
    };
  }
}
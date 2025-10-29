// lib/models/concept_node.dart

class ConceptNode {
  final String id;        // Düğümün benzersiz kimliği (Örn: "N1")
  final String text;      // Düğümde gösterilecek kavram veya metin
  final String type;      // Kavram türü (Örn: "Topic", "Idea", "Action")
  
  // Harita görselleştirmesi için pozisyon (şimdilik opsiyonel)
  final double? x; 
  final double? y;

  ConceptNode({
    required this.id,
    required this.text,
    required this.type,
    this.x,
    this.y,
  });

  // LLM'den gelecek JSON verisini Dart objesine çevirme (Factory Constructor)
  factory ConceptNode.fromJson(Map<String, dynamic> json) {
    return ConceptNode(
      id: json['id'] as String,
      text: json['text'] as String,
      type: json['type'] as String,
      x: json['x'] as double?,
      y: json['y'] as double?,
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
// lib/core/services/map_edit_service.dart

import 'package:innermap/models/concept_node.dart';
import 'package:innermap/models/concept_edge.dart';
import 'dart:math';

class MapEditService {
  
  // 🎯 LLM'den Gelen Yeni Düğümleri Mevcut Haritayla Birleştirir
  // Bu fonksiyon, bir haritayı yükledikten sonra üzerine yeni fikir ekleme mantığı için kullanılır.
  Map<String, List<dynamic>> mergeMaps({
    required List<ConceptNode> existingNodes,
    required List<ConceptEdge> existingEdges,
    required Map<String, dynamic> llmNewData,
  }) {
    // 1. LLM'den gelen veriyi Dart objelerine çevir
    final List<ConceptNode> newNodes = (llmNewData['nodes'] as List)
        .map((item) => ConceptNode.fromJson(item as Map<String, dynamic>))
        .toList();
    final List<ConceptEdge> newEdges = (llmNewData['edges'] as List)
        .map((item) => ConceptEdge.fromJson(item as Map<String, dynamic>))
        .toList();

    // 2. Düğüm Birleştirme: Mükerrer düğümleri ve ID çakışmasını yönet
    final List<ConceptNode> mergedNodes = List.from(existingNodes);
    final Set<String> existingNodeIds = existingNodes.map((n) => n.id).toSet();

    for (final newNode in newNodes) {
      // LLM'in her zaman benzersiz ID'ler döndürmesini garanti et
      if (existingNodeIds.contains(newNode.id)) {
        // ID çakışıyorsa, yeni bir ID oluşturup copyWith ile yeni bir düğüm nesnesi oluştururuz.
        final newUniqueId = 'N${Random().nextInt(999999) + 100000}'; 
        
        // copyWith metodu ile ID'si değiştirilmiş yeni bir ConceptNode yarat
        final updatedNode = newNode.copyWith(id: newUniqueId);
        mergedNodes.add(updatedNode);
      } else {
        // ID çakışmıyorsa direkt ekle
        mergedNodes.add(newNode);
      }
    }

    // 3. Bağlantı Birleştirme: Tüm eski ve yeni bağlantıları ekle
    final List<ConceptEdge> mergedEdges = List.from(existingEdges)..addAll(newEdges);
    
    // Final Map'i döndür
    return {
      'nodes': mergedNodes,
      'edges': mergedEdges,
    };
  }
}
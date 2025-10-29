// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';

class MapScreen extends StatelessWidget {
  // 🚨 YENİ: LLM'den gelen veriyi tutacak alanlar eklendi
  final List<ConceptNode> nodes;
  final List<ConceptEdge> edges;

  const MapScreen({
    super.key,
    required this.nodes,
    required this.edges,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kavram Haritası (Analiz Sonucu)'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LLM Analiz Sonucu:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Analiz edilen Node sayısını göster
              Text('Düğüm Sayısı (Nodes): ${nodes.length}', style: const TextStyle(fontSize: 16)),
              // Analiz edilen Edge sayısını göster
              Text('Bağlantı Sayısı (Edges): ${edges.length}', style: const TextStyle(fontSize: 16)),
              
              const SizedBox(height: 20),
              
              const Text(
                'Harita görselleştirmesi bu alana gelecek. (3. ve 4. Hafta)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              
              const SizedBox(height: 30),

              // Test için gelen Node metinlerinden birini gösterelim
              if (nodes.isNotEmpty) 
                Column(
                  children: [
                    const Text('İlk Düğüm:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(nodes.first.text),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:innermap/core/services/storage_service.dart';
import 'package:innermap/models/map_entry.dart';
import 'package:intl/intl.dart'; 
import 'dart:convert';
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';
import 'package:innermap/screens/map_screen.dart'; 

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  
  // Kaydedilen haritaları tutacak liste
  late Future<List<MapEntry>> _futureMapEntries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }
  
  void _loadEntries() {
    setState(() {
      _futureMapEntries = _storageService.loadAllMapEntries();
    });
  }

  // --- Yardımcı Fonksiyon: Haritayı Yükleme ve MapScreen'e Yönlendirme ---
  void _loadAndNavigate(MapEntry entry) {
    try {
      // 1. Kayıtlı JSON String'i Map'e Çevir
      final Map<String, dynamic> data = json.decode(entry.jsonData);
      
      // 2. Map'i ConceptNode/Edge Listelerine Çevir
      final List<ConceptNode> nodes = (data['nodes'] as List)
          .map((item) => ConceptNode.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final List<ConceptEdge> edges = (data['edges'] as List)
          .map((item) => ConceptEdge.fromJson(item as Map<String, dynamic>))
          .toList();
          
      // 3. MapScreen'e Yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(nodes: nodes, edges: edges),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: Kayıt yüklenirken veri formatı hatası oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fikir Geçmişi'),
      ),
      body: FutureBuilder<List<MapEntry>>(
        future: _futureMapEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz kaydedilmiş bir harita yok.'));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                
                // Tarihi daha okunur hale getirme
                final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(entry.timestamp);

                return ListTile(
                  title: Text(entry.title),
                  subtitle: Text('Kaydedilme: $formattedDate'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _storageService.deleteMapEntry(entry.id);
                      // Silme sonrası listeyi yeniden yükle
                      _loadEntries(); 
                    },
                  ),
                  onTap: () => _loadAndNavigate(entry),
                );
              },
            );
          }
        },
      ),
    );
  }
}
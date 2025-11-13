// lib/screens/navigation_shell.dart

import 'package:flutter/material.dart';
import 'package:innermap/screens/history_screen.dart'; 
import 'package:innermap/screens/home_screen_mock.dart';
import 'package:innermap/screens/map_screen.dart';
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';
import 'dart:convert';


class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0; 
  // LLM'den gelen veriyi tutacak önbellek
  Map<String, dynamic>? _cachedMapData; 

  // --- Callback Fonksiyonu: HomeScreen'den Veriyi Alır ---
  void _handleAnalysisComplete(Map<String, dynamic> data) {
    setState(() {
      _cachedMapData = data;
      // Veri geldiğinde Harita ikonunu göster (opsiyonel görsel geri bildirim)
    });
  }
  
  // --- Harita İkonuna Dokunma Mantığı ---
  void _onTabTapped(int index) {
    if (index == 1) { // Eğer kullanıcı HARİTA ikonuna dokunursa
      if (_cachedMapData != null) {
        // Veri varsa, Harita ekranını aç
        
        // JSON'u Dart modellerine çevirme
        final List<ConceptNode> nodes = (_cachedMapData!['nodes'] as List)
            .map((item) => ConceptNode.fromJson(item as Map<String, dynamic>))
            .toList();
        final List<ConceptEdge> edges = (_cachedMapData!['edges'] as List)
            .map((item) => ConceptEdge.fromJson(item as Map<String, dynamic>))
            .toList();

        // MapScreen'e yönlendir
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MapScreen(nodes: nodes, edges: edges),
          ),
        );
        // Harita açıldıktan sonra önbelleği temizleyebiliriz
        _cachedMapData = null; 
        
      } else {
        // Veri yoksa uyarı ver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce Giriş sekmesinden bir fikir analizi yapın.')),
        );
      }
      return;
    }
    
    // Giriş (0) veya Geçmiş (2) sekmelerine geçiş
    setState(() {
      _currentIndex = (index == 2) ? 1 : index; // Index 2'yi yeni 1'e ayarlıyoruz
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ekranlar: MapScreen yönlendirildiği için listede yer almaz
    final List<Widget> _screens = [
      // HomeScreen, callback ile NavigationShell'e bağlanır
      HomeScreenMock(onAnalysisComplete: _handleAnalysisComplete), // Index 0
      const HistoryScreen(), // Index 1
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Giriş'),
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Harita'), // Harita ikonu
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Geçmiş'),
        ],
      ),
    );
  }
}
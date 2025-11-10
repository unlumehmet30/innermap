// lib/screens/navigation_shell.dart

import 'package:flutter/material.dart';
import 'package:innermap/screens/history_screen.dart'; 
import 'package:innermap/screens/home_screen_mock.dart'; // Veya LLM entegreli home_screen.dart
// Harita ekranı, Home ekranından yönlendirildiği için burada listelenmeyecek.

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0; // Şu anki seçili sayfa indeksi

  // Uygulamanın alt navigasyonda gösterilecek ana sayfaları
  final List<Widget> _screens = [
    const HomeScreenMock(), // 🚨 Kullanmak istediğiniz HomeScreen'i buraya koyun
    const Center(child: Text("Harita Yönlendirme Alanı")), // MapScreen'e Home'dan geçildiği için burada sadece placeholder var.
    const HistoryScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 1) {
      // Harita ekranı alt navigasyonda sadece placeholder olmalı.
      // Harita ekranına daima fikir girişi (HomeScreen) üzerinden geçilmelidir.
      return; 
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Seçili olan ekranı göster
      body: _screens[_currentIndex],
      
      // Alt Navigasyon Çubuğu
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Giriş'),
          // Harita simgesi, MapScreen'e Home üzerinden geçişi teşvik eder.
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Harita'), 
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Geçmiş'),
        ],
      ),
    );
  }
}
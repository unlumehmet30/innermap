
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:innermap/screens/home_screen.dart'; // Kendi HomeScreen dosyanızın yolunu kullanın

void main() {
  // Flutter widget'larının başlatıldığından emin olmak için
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uygulamayı başlat
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innermap MVP',
      // Basit bir tema belirleme
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false, 
      ),
      // Uygulamanın başladığı ekran (İlk hafta ana ekranımız)
      home: const HomeScreen(), 
    );
  }
}
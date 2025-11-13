// lib/main.dart

import 'package:flutter/material.dart';
import 'package:innermap/screens/login_screen.dart'; 

void main() {
  // SharedPreferences'ı kullanmak için bu şarttır
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innermap MVP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false, 
      ),
      // 🚨 Uygulamanın giriş noktası LoginScreen olarak ayarlandı
      home: const LoginScreen(), 
    );
  }
}
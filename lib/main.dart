// lib/main.dart

import 'package:flutter/material.dart';
import 'package:innermap/screens/navigation_shell.dart'; // Yeni navigasyon kabuğu

void main() {
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
      // Uygulamanın giriş noktasını navigasyon kabuğu yapıyoruz.
      home: const NavigationShell(), 
    );
  }
}
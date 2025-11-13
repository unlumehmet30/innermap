// lib/screens/login_screen.dart (Çoklu Profil Yönetimi)

import 'package:flutter/material.dart';
import 'package:innermap/core/services/storage_service.dart';
import 'package:innermap/screens/navigation_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final StorageService _storageService = StorageService();
  String _errorMessage = '';
  
  // Profil Seçimi için
  List<String> _availableUsernames = [];
  String? _selectedUsername;

  @override
  void initState() {
    super.initState();
    _loadUsernames();
  }
  
  // Kayıtlı kullanıcı adlarını yükler
  Future<void> _loadUsernames() async {
    final usernames = await _storageService.getAllUsernames();
    setState(() {
      _availableUsernames = usernames;
      _selectedUsername = usernames.isNotEmpty ? usernames.first : null;
    });
  }

  Future<void> _attemptLogin() async {
    final username = _selectedUsername ?? _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen kullanıcı adı ve şifre girin.';
      });
      return;
    }

    setState(() {
      _errorMessage = 'Giriş kontrol ediliyor...';
    });

    final success = await _storageService.checkUserCredentials(username, password);

    if (success) {
      // Başarılı giriş: Ana navigasyon kabuğuna yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavigationShell()),
      );
    } else {
      setState(() {
        _errorMessage = 'Hata: Kullanıcı adı veya şifre yanlış.';
      });
    }
  }
  
  Future<void> _attemptRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Kayıt için kullanıcı adı ve şifre gereklidir.';
      });
      return;
    }
    
    final success = await _storageService.registerUser(username, password);
    
    if (success) {
      // Başarılı kayıt sonrası otomatik giriş yap ve listeyi güncelle
      await _loadUsernames(); // Yeni kullanıcı adı listeye eklenir
      _selectedUsername = username; 
      _passwordController.clear();
      setState(() {
        _errorMessage = 'Kayıt başarılı! Lütfen şifrenizi girin.';
      });
    } else {
      setState(() {
        _errorMessage = 'Hata: Kullanıcı adı ($username) zaten kullanılıyor.';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isNewUserMode = _availableUsernames.isEmpty || _selectedUsername == 'Yeni Profil';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Innermap Profil Seçimi')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Innermap Profili',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- PROFİL SEÇİMİ (Dropdown) ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Seç / Yeni Kayıt',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_pin),
                ),
                value: _selectedUsername,
                items: [
                  ..._availableUsernames.map((name) => DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  )).toList(),
                  const DropdownMenuItem(
                    value: 'Yeni Profil',
                    child: Text('Yeni Profil Oluştur...'),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUsername = newValue;
                    _passwordController.clear(); // Şifreyi temizle
                    _errorMessage = '';
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // --- YENİ KULLANICI ADI GİRİŞİ (Sadece Yeni Profil Seçiliyse) ---
              if (isNewUserMode)
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Kullanıcı Adı Girin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_add),
                  ),
                ),
              const SizedBox(height: 16),
              
              // --- ŞİFRE GİRİŞİ ---
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isNewUserMode ? 'Yeni Şifre Belirleyin' : 'Şifre',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: _errorMessage.startsWith('Hata') ? Colors.red : Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // --- GİRİŞ/KAYIT BUTONLARI ---
              if (!isNewUserMode)
                ElevatedButton(
                  onPressed: _attemptLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Giriş Yap', style: TextStyle(fontSize: 18)),
                )
              else
                ElevatedButton(
                  onPressed: _attemptRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Profili Kaydet ve Giriş Yap', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
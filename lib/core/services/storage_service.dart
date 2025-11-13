// lib/core/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innermap/models/map_entry.dart'; 

// Kullanıcı profili için basit bir model
class UserProfile {
  final String username;
  final String password;

  UserProfile({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
  factory UserProfile.fromJson(Map<String, dynamic> json) => 
      UserProfile(username: json['username'] as String, password: json['password'] as String);
}

class StorageService {
  static const String _mapEntriesKey = 'innermap_saved_maps';
  static const String _usersListKey = 'innermap_users_list'; 
  
  // --- HARİTA KAYDETME METODLARI ---
  
  Future<void> saveMapEntry(MapEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final String currentJson = prefs.getString(_mapEntriesKey) ?? '[]';
    List<dynamic> currentList = json.decode(currentJson);

    final newEntryJson = entry.toJson();
    
    // Var olanı güncelle (ID'ye göre) veya yeni ekle
    final existingIndex = currentList.indexWhere((e) => e['id'] == entry.id);
    if (existingIndex >= 0) {
      currentList[existingIndex] = newEntryJson; // Güncelleme
    } else {
      currentList.add(newEntryJson); // Yeni ekleme
    }
    
    final String updatedJson = json.encode(currentList);
    await prefs.setString(_mapEntriesKey, updatedJson);
  }

  Future<List<MapEntry>> loadAllMapEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = prefs.getString(_mapEntriesKey) ?? '[]';

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => MapEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Harita yükleme hatası: $e');
      return [];
    }
  }

  Future<void> deleteMapEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<MapEntry> entries = await loadAllMapEntries();
    
    entries.removeWhere((entry) => entry.id == id);

    final List<Map<String, dynamic>> updatedJsonList = 
        entries.map((entry) => entry.toJson()).toList();
        
    final String updatedJson = json.encode(updatedJsonList);
    await prefs.setString(_mapEntriesKey, updatedJson);
  }
  
  // --- ÇOKLU PROFİL YÖNETİM METODLARI ---

  Future<List<UserProfile>> _loadAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String usersJson = prefs.getString(_usersListKey) ?? '[]';
    
    try {
      List<dynamic> usersList = json.decode(usersJson);
      return usersList.map((json) => UserProfile.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> registerUser(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<UserProfile> users = await _loadAllUsers();
    
    if (users.any((user) => user.username == username)) {
      return false; // Kullanıcı adı zaten kullanılıyor
    }
    
    users.add(UserProfile(username: username, password: password));
    
    final List<Map<String, dynamic>> usersJsonList = users.map((u) => u.toJson()).toList();
    await prefs.setString(_usersListKey, json.encode(usersJsonList));
    
    return true; // Kayıt başarılı
  }

  Future<bool> checkUserCredentials(String username, String password) async {
    List<UserProfile> users = await _loadAllUsers();
    
    // Yalnızca kayıtlı kullanıcılar arasında kontrol et
    return users.any((user) => user.username == username && user.password == password);
  }

  Future<List<String>> getAllUsernames() async {
    List<UserProfile> users = await _loadAllUsers();
    return users.map((u) => u.username).toList();
  }
}
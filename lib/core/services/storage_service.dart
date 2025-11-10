// lib/core/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innermap/models/map_entry.dart';

class StorageService {
  // Kayıtların tutulacağı anahtar
  static const String _mapEntriesKey = 'innermap_saved_maps';

  // 1. HARİTAYI KAYDETME
  Future<void> saveMapEntry(MapEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Mevcut kayıtları oku
    final String existingJson = prefs.getString(_mapEntriesKey) ?? '[]';
    List<dynamic> entriesList = json.decode(existingJson);
    
    // Yeni kaydı ekle (veya aynı ID varsa üzerine yaz)
    final existingIndex = entriesList.indexWhere((e) => e['id'] == entry.id);
    
    if (existingIndex >= 0) {
      // Var olan kaydı güncelle
      entriesList[existingIndex] = entry.toJson();
    } else {
      // Yeni kayıt olarak ekle
      entriesList.add(entry.toJson());
    }

    // Güncellenmiş listeyi kaydet
    await prefs.setString(_mapEntriesKey, json.encode(entriesList));
    print('Harita Kaydedildi: ${entry.title}');
  }

  // 2. TÜM KAYITLARI OKUMA (Geçmiş Ekranı İçin)
  Future<List<MapEntry>> loadAllMapEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String entriesJson = prefs.getString(_mapEntriesKey) ?? '[]';
    
    try {
      List<dynamic> entriesList = json.decode(entriesJson);
      
      return entriesList
          .map((json) => MapEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Kayıt Okuma Hatası: $e');
      return [];
    }
  }

  // 3. TEK BİR KAYDI SİLME
  Future<void> deleteMapEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String existingJson = prefs.getString(_mapEntriesKey) ?? '[]';
    List<dynamic> entriesList = json.decode(existingJson);
    
    // İlgili kaydı listeden çıkar
    entriesList.removeWhere((e) => e['id'] == id);
    
    // Yeni listeyi kaydet
    await prefs.setString(_mapEntriesKey, json.encode(entriesList));
    print('Harita Silindi: ID $id');
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aliment.dart';
import '../models/repas.dart';
import '../models/entrainement.dart';
import '../models/mesures_corporelles.dart';
import '../models/parametres_nutritionnels.dart';

class StorageService {
  static const String _keyAliments = 'aliments';
  static const String _keyRepas = 'repas';
  static const String _keyEntrainements = 'entrainements';
  static const String _keyMesures = 'mesures';
  static const String _keyParametresNutritionnels = 'parametres_nutritionnels';

  // Méthodes pour les aliments
  Future<void> saveAliments(List<Aliment> aliments) async {
    final prefs = await SharedPreferences.getInstance();
    final alimentsJson = aliments.map((a) => a.toMap()).toList();
    await prefs.setString(_keyAliments, jsonEncode(alimentsJson));
  }

  Future<List<Aliment>> getAliments() async {
    final prefs = await SharedPreferences.getInstance();
    final alimentsJson = prefs.getString(_keyAliments);
    if (alimentsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(alimentsJson);
    return decoded.map((json) => Aliment.fromMap(json)).toList();
  }

  Future<void> addAliment(Aliment aliment) async {
    final aliments = await getAliments();
    aliments.add(aliment);
    await saveAliments(aliments);
  }

  Future<void> updateAliment(Aliment aliment) async {
    final aliments = await getAliments();
    final index = aliments.indexWhere((a) => a.id == aliment.id);
    if (index != -1) {
      aliments[index] = aliment;
      await saveAliments(aliments);
    }
  }

  Future<void> deleteAliment(String id) async {
    final aliments = await getAliments();
    aliments.removeWhere((a) => a.id == id);
    await saveAliments(aliments);
  }

  // Méthodes pour les repas
  Future<void> saveRepas(List<Repas> repas) async {
    final prefs = await SharedPreferences.getInstance();
    final repasJson = repas.map((r) => r.toMap()).toList();
    await prefs.setString(_keyRepas, jsonEncode(repasJson));
  }

  Future<List<Repas>> getRepas() async {
    final prefs = await SharedPreferences.getInstance();
    final repasJson = prefs.getString(_keyRepas);
    if (repasJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(repasJson);
    return decoded.map((json) => Repas.fromMap(json)).toList();
  }

  Future<void> addRepas(Repas repas) async {
    final listeRepas = await getRepas();
    listeRepas.add(repas);
    await saveRepas(listeRepas);
  }

  Future<void> updateRepas(Repas repas) async {
    final listeRepas = await getRepas();
    final index = listeRepas.indexWhere((r) => r.id == repas.id);
    if (index != -1) {
      listeRepas[index] = repas;
      await saveRepas(listeRepas);
    }
  }

  Future<void> deleteRepas(String id) async {
    final listeRepas = await getRepas();
    listeRepas.removeWhere((r) => r.id == id);
    await saveRepas(listeRepas);
  }

  // Méthodes pour les entraînements
  Future<void> saveEntrainements(List<Entrainement> entrainements) async {
    final prefs = await SharedPreferences.getInstance();
    final entrainementsJson = entrainements.map((e) => e.toMap()).toList();
    await prefs.setString(_keyEntrainements, jsonEncode(entrainementsJson));
  }

  Future<List<Entrainement>> getEntrainements() async {
    final prefs = await SharedPreferences.getInstance();
    final entrainementsJson = prefs.getString(_keyEntrainements);
    if (entrainementsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(entrainementsJson);
    return decoded.map((json) {
      switch (json['type']) {
        case 'cardio':
          return EntrainementCardio.fromMap(json);
        case 'musculation':
          return EntrainementMusculation.fromMap(json);
        case 'divers':
          return EntrainementDivers.fromMap(json);
        default:
          throw Exception('Type d\'entraînement inconnu');
      }
    }).toList();
  }

  Future<void> addEntrainement(Entrainement entrainement) async {
    final entrainements = await getEntrainements();
    entrainements.add(entrainement);
    await saveEntrainements(entrainements);
  }

  Future<void> updateEntrainement(Entrainement entrainement) async {
    final entrainements = await getEntrainements();
    final index = entrainements.indexWhere((e) => e.id == entrainement.id);
    if (index != -1) {
      entrainements[index] = entrainement;
      await saveEntrainements(entrainements);
    }
  }

  Future<void> deleteEntrainement(String id) async {
    final entrainements = await getEntrainements();
    entrainements.removeWhere((e) => e.id == id);
    await saveEntrainements(entrainements);
  }

  // Méthodes pour les mesures corporelles
  Future<void> saveMesures(List<MesuresCorporelles> mesures) async {
    final prefs = await SharedPreferences.getInstance();
    final mesuresJson = mesures.map((m) => m.toMap()).toList();
    await prefs.setString(_keyMesures, jsonEncode(mesuresJson));
  }

  Future<List<MesuresCorporelles>> getMesures() async {
    final prefs = await SharedPreferences.getInstance();
    final mesuresJson = prefs.getString(_keyMesures);
    if (mesuresJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(mesuresJson);
    return decoded.map((json) => MesuresCorporelles.fromMap(json)).toList();
  }

  Future<void> addMesure(MesuresCorporelles mesure) async {
    final mesures = await getMesures();
    mesures.add(mesure);
    await saveMesures(mesures);
  }

  Future<void> updateMesure(MesuresCorporelles mesure) async {
    final mesures = await getMesures();
    final index = mesures.indexWhere((m) => m.id == mesure.id);
    if (index != -1) {
      mesures[index] = mesure;
      await saveMesures(mesures);
    }
  }

  Future<void> deleteMesure(String id) async {
    final mesures = await getMesures();
    mesures.removeWhere((m) => m.id == id);
    await saveMesures(mesures);
  }

  // Méthodes pour les paramètres nutritionnels
  Future<ParametresNutritionnels?> getParametresNutritionnels() async {
    final prefs = await SharedPreferences.getInstance();
    final parametresJson = prefs.getString(_keyParametresNutritionnels);
    if (parametresJson == null) return null;
    
    final Map<String, dynamic> decoded = jsonDecode(parametresJson);
    return ParametresNutritionnels.fromMap(decoded);
  }

  Future<void> saveParametresNutritionnels(ParametresNutritionnels parametres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParametresNutritionnels, jsonEncode(parametres.toMap()));
  }
} 
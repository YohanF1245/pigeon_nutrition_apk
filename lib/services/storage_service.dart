import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aliment.dart';
import '../models/repas.dart';
import '../models/entrainement.dart';
import '../models/mesures_corporelles.dart';
import '../models/parametres_nutritionnels.dart';
import 'repas_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  final _repasService = RepasService();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

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
  Future<List<Repas>> getRepas() async {
    return await _repasService.getRepas();
  }

  Future<void> saveRepas(Repas repas) async {
    await _repasService.sauvegarderRepas(repas);
  }

  Future<void> deleteRepas(String id) async {
    await _repasService.supprimerRepas(id);
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
    final String? parametresJson = prefs.getString('parametres_nutritionnels');
    if (parametresJson == null) return null;
    return ParametresNutritionnels.fromMap(jsonDecode(parametresJson));
  }

  Future<void> saveParametresNutritionnels(ParametresNutritionnels parametres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parametres_nutritionnels', jsonEncode(parametres.toMap()));
  }
} 
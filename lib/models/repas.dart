import 'package:uuid/uuid.dart';
import 'aliment.dart';

class RepasAliment {
  final String alimentId;
  final double quantite;

  RepasAliment({
    required this.alimentId,
    required this.quantite,
  });

  Map<String, dynamic> toMap() {
    return {
      'alimentId': alimentId,
      'quantite': quantite,
    };
  }

  factory RepasAliment.fromMap(Map<String, dynamic> map) {
    return RepasAliment(
      alimentId: map['alimentId'],
      quantite: map['quantite'],
    );
  }
}

class Repas {
  final String id;
  String nom;
  DateTime dateHeure;
  List<RepasAliment> aliments;
  Map<String, double>? nutrimentsCaches;

  Repas({
    String? id,
    required this.nom,
    required this.dateHeure,
    required this.aliments,
    this.nutrimentsCaches,
  }) : id = id ?? const Uuid().v4();

  // Méthodes de calcul des nutriments
  Future<Map<String, double>> calculerNutriments(List<Aliment> alimentsDisponibles) async {
    if (nutrimentsCaches != null) return nutrimentsCaches!;

    double calories = 0;
    double proteines = 0;
    double lipides = 0;
    double glucides = 0;

    for (var repasAliment in aliments) {
      final aliment = alimentsDisponibles.firstWhere(
        (a) => a.id == repasAliment.alimentId,
        orElse: () => throw Exception('Aliment non trouvé: ${repasAliment.alimentId}'),
      );

      // Calcul en fonction de la quantité
      final ratio = repasAliment.quantite / 100; // Les nutriments sont pour 100g/ml
      calories += aliment.calories * ratio;
      proteines += aliment.proteines * ratio;
      lipides += aliment.lipides * ratio;
      glucides += aliment.glucides * ratio;
    }

    nutrimentsCaches = {
      'calories': calories,
      'proteines': proteines,
      'lipides': lipides,
      'glucides': glucides,
    };

    return nutrimentsCaches!;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'dateHeure': dateHeure.toIso8601String(),
      'aliments': aliments.map((a) => a.toMap()).toList(),
      'nutrimentsCaches': nutrimentsCaches,
    };
  }

  factory Repas.fromMap(Map<String, dynamic> map) {
    return Repas(
      id: map['id'],
      nom: map['nom'],
      dateHeure: DateTime.parse(map['dateHeure']),
      aliments: (map['aliments'] as List)
          .map((a) => RepasAliment.fromMap(a as Map<String, dynamic>))
          .toList(),
      nutrimentsCaches: map['nutrimentsCaches'] != null
          ? Map<String, double>.from(map['nutrimentsCaches'])
          : null,
    );
  }

  // Clone le repas avec de nouvelles valeurs optionnelles
  Repas copyWith({
    String? nom,
    DateTime? dateHeure,
    List<RepasAliment>? aliments,
  }) {
    return Repas(
      id: id, // On garde le même ID
      nom: nom ?? this.nom,
      dateHeure: dateHeure ?? this.dateHeure,
      aliments: aliments ?? List.from(this.aliments),
      nutrimentsCaches: null, // On reset le cache car les données peuvent avoir changé
    );
  }
} 
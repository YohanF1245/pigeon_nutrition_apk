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
  List<RepasAliment> aliments;
  Map<String, double>? nutrimentsCaches;
  DateTime? createdAt;

  Repas({
    String? id,
    required this.nom,
    required this.aliments,
    this.nutrimentsCaches,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

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
      'aliments': aliments.map((a) => a.toMap()).toList(),
      'nutrimentsCaches': nutrimentsCaches,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Repas.fromMap(Map<String, dynamic> map) {
    return Repas(
      id: map['id'],
      nom: map['nom'],
      aliments: (map['aliments'] as List)
          .map((a) => RepasAliment.fromMap(a as Map<String, dynamic>))
          .toList(),
      nutrimentsCaches: map['nutrimentsCaches'] != null
          ? Map<String, double>.from(map['nutrimentsCaches'])
          : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  // Clone le repas avec de nouvelles valeurs optionnelles
  Repas copyWith({
    String? nom,
    List<RepasAliment>? aliments,
  }) {
    return Repas(
      id: id,
      nom: nom ?? this.nom,
      aliments: aliments ?? List.from(this.aliments),
      nutrimentsCaches: null, // On reset le cache car les données peuvent avoir changé
      createdAt: createdAt,
    );
  }
} 
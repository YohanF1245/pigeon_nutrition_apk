abstract class Entrainement {
  String id;
  DateTime date;
  String type; // 'cardio', 'musculation', 'divers'
  int dureeMinutes;

  Entrainement({
    required this.id,
    required this.date,
    required this.type,
    required this.dureeMinutes,
  });

  Map<String, dynamic> toMap();
}

class EntrainementCardio extends Entrainement {
  double distance; // en km
  double caloriesBrulees;

  EntrainementCardio({
    required String id,
    required DateTime date,
    required int dureeMinutes,
    required this.distance,
    required this.caloriesBrulees,
  }) : super(
          id: id,
          date: date,
          type: 'cardio',
          dureeMinutes: dureeMinutes,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'dureeMinutes': dureeMinutes,
      'distance': distance,
      'caloriesBrulees': caloriesBrulees,
    };
  }

  factory EntrainementCardio.fromMap(Map<String, dynamic> map) {
    return EntrainementCardio(
      id: map['id'],
      date: DateTime.parse(map['date']),
      dureeMinutes: map['dureeMinutes'],
      distance: map['distance'],
      caloriesBrulees: map['caloriesBrulees'],
    );
  }
}

class ExerciceMusculation {
  String nom;
  int series;
  int repetitions;
  double poids; // en kg
  String muscle; // groupe musculaire ciblé

  ExerciceMusculation({
    required this.nom,
    required this.series,
    required this.repetitions,
    required this.poids,
    required this.muscle,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'series': series,
      'repetitions': repetitions,
      'poids': poids,
      'muscle': muscle,
    };
  }

  factory ExerciceMusculation.fromMap(Map<String, dynamic> map) {
    return ExerciceMusculation(
      nom: map['nom'],
      series: map['series'],
      repetitions: map['repetitions'],
      poids: map['poids'],
      muscle: map['muscle'],
    );
  }
}

class EntrainementMusculation extends Entrainement {
  List<ExerciceMusculation> exercices;

  EntrainementMusculation({
    required String id,
    required DateTime date,
    required int dureeMinutes,
    required this.exercices,
  }) : super(
          id: id,
          date: date,
          type: 'musculation',
          dureeMinutes: dureeMinutes,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'dureeMinutes': dureeMinutes,
      'exercices': exercices.map((e) => e.toMap()).toList(),
    };
  }

  factory EntrainementMusculation.fromMap(Map<String, dynamic> map) {
    return EntrainementMusculation(
      id: map['id'],
      date: DateTime.parse(map['date']),
      dureeMinutes: map['dureeMinutes'],
      exercices: (map['exercices'] as List)
          .map((e) => ExerciceMusculation.fromMap(e))
          .toList(),
    );
  }
}

class EntrainementDivers extends Entrainement {
  String activite; // 'marche', 'vélo', etc.
  double? distance; // en km (optionnel)
  double? caloriesBrulees; // (optionnel)

  EntrainementDivers({
    required String id,
    required DateTime date,
    required int dureeMinutes,
    required this.activite,
    this.distance,
    this.caloriesBrulees,
  }) : super(
          id: id,
          date: date,
          type: 'divers',
          dureeMinutes: dureeMinutes,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'dureeMinutes': dureeMinutes,
      'activite': activite,
      'distance': distance,
      'caloriesBrulees': caloriesBrulees,
    };
  }

  factory EntrainementDivers.fromMap(Map<String, dynamic> map) {
    return EntrainementDivers(
      id: map['id'],
      date: DateTime.parse(map['date']),
      dureeMinutes: map['dureeMinutes'],
      activite: map['activite'],
      distance: map['distance'],
      caloriesBrulees: map['caloriesBrulees'],
    );
  }
} 
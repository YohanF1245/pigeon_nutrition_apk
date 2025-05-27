import 'aliment.dart';

class RepasAliment {
  final Aliment aliment;
  final double quantite;
  final String unite;

  RepasAliment({
    required this.aliment,
    required this.quantite,
    required this.unite,
  });

  Map<String, dynamic> toMap() {
    return {
      'aliment': aliment.toMap(),
      'quantite': quantite,
      'unite': unite,
    };
  }

  factory RepasAliment.fromMap(Map<String, dynamic> map) {
    return RepasAliment(
      aliment: Aliment.fromMap(map['aliment']),
      quantite: map['quantite'],
      unite: map['unite'],
    );
  }
}

class Repas {
  String id;
  String nom;
  List<RepasAliment> aliments;
  DateTime date;
  String type; // 'petit-déjeuner', 'déjeuner', 'dîner', 'collation'

  Repas({
    required this.id,
    required this.nom,
    required this.aliments,
    required this.date,
    required this.type,
  });

  double get totalProteines {
    return aliments.fold(0, (sum, repasAliment) {
      double facteur = repasAliment.quantite / 100; // conversion en base 100g
      if (repasAliment.unite == 'kg') facteur *= 1000;
      return sum + (repasAliment.aliment.proteines * facteur);
    });
  }

  double get totalLipides {
    return aliments.fold(0, (sum, repasAliment) {
      double facteur = repasAliment.quantite / 100;
      if (repasAliment.unite == 'kg') facteur *= 1000;
      return sum + (repasAliment.aliment.lipides * facteur);
    });
  }

  double get totalGlucides {
    return aliments.fold(0, (sum, repasAliment) {
      double facteur = repasAliment.quantite / 100;
      if (repasAliment.unite == 'kg') facteur *= 1000;
      return sum + (repasAliment.aliment.glucides * facteur);
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'aliments': aliments.map((a) => a.toMap()).toList(),
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  factory Repas.fromMap(Map<String, dynamic> map) {
    return Repas(
      id: map['id'],
      nom: map['nom'],
      aliments: (map['aliments'] as List)
          .map((a) => RepasAliment.fromMap(a))
          .toList(),
      date: DateTime.parse(map['date']),
      type: map['type'],
    );
  }
} 
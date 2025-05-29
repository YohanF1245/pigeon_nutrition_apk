class ParametresNutritionnels {
  String id;
  // Données physiques
  double poids; // en kg
  double taille; // en cm
  int age;
  String sexe; // 'homme' ou 'femme'
  String niveauActivite; // 'sedentaire', 'leger', 'modere', 'intense', 'tres_intense'
  String objectif; // 'perte', 'maintien', 'prise'

  // Objectifs macronutriments (en pourcentage)
  double objectifProteines; // par défaut 30%
  double objectifLipides; // par défaut 25%
  double objectifGlucides; // par défaut 45%

  // Valeurs calculées
  double tmb = 0; // Taux Métabolique de Base
  double caloriesQuotidiennes = 0;
  double objectifProteinesGrammes = 0;
  double objectifLipidesGrammes = 0;
  double objectifGlucidesGrammes = 0;

  // Valeur en g/kg pour les protéines
  double proteinesParKg = 1.6;

  ParametresNutritionnels({
    required this.id,
    required this.poids,
    required this.taille,
    required this.age,
    required this.sexe,
    required this.niveauActivite,
    required this.objectif,
    this.objectifProteines = 30,
    this.objectifLipides = 25,
    this.objectifGlucides = 45,
  }) {
    calculerBesoins(objectif: objectif);
  }

  void calculerBesoins({String? objectif, bool calculAutomatique = true}) {
    final obj = objectif ?? this.objectif;
    
    // Calcul du TMB selon la formule de Mifflin-St Jeor
    if (sexe == 'homme') {
      tmb = (10 * poids) + (6.25 * taille) - (5 * age) + 5;
    } else {
      tmb = (10 * poids) + (6.25 * taille) - (5 * age) - 161;
    }

    // Calcul du facteur d'activité
    double facteurActivite = switch (niveauActivite) {
      'sedentaire' => 1.2,
      'leger' => 1.375,
      'modere' => 1.55,
      'intense' => 1.725,
      'tres_intense' => 1.9,
      _ => 1.2,
    };

    // Calcul des calories quotidiennes
    double tdee = tmb * facteurActivite;
    double caloriesObjectif = tdee;
    if (obj == 'perte') {
      caloriesObjectif = tdee * 0.8;
    } else if (obj == 'prise') {
      caloriesObjectif = tdee * 1.1;
    }
    caloriesQuotidiennes = caloriesObjectif;

    if (calculAutomatique) {
      // Calcul automatique des macronutriments selon l'objectif
      switch (obj) {
        case 'perte':
          proteinesParKg = 2.2;
          objectifLipides = 30;
          break;
        case 'maintien':
          proteinesParKg = 1.8;
          objectifLipides = 25;
          break;
        case 'prise':
          proteinesParKg = 1.7;
          objectifLipides = 20;
          break;
      }

      // Calcul des grammes de protéines
      objectifProteinesGrammes = poids * proteinesParKg;
      
      // Calcul du pourcentage de protéines
      objectifProteines = (objectifProteinesGrammes * 4 / caloriesObjectif) * 100;

      // Calcul des grammes de lipides
      objectifLipidesGrammes = (caloriesObjectif * objectifLipides / 100) / 9;

      // Calcul des glucides (reste des calories)
      double caloriesProteines = objectifProteinesGrammes * 4;
      double caloriesLipides = objectifLipidesGrammes * 9;
      double caloriesGlucides = caloriesObjectif - caloriesProteines - caloriesLipides;
      objectifGlucidesGrammes = caloriesGlucides / 4;
      objectifGlucides = (caloriesGlucides / caloriesObjectif) * 100;
    } else {
      // Calcul manuel basé sur les pourcentages
      objectifProteinesGrammes = (caloriesObjectif * objectifProteines / 100) / 4;
      objectifLipidesGrammes = (caloriesObjectif * objectifLipides / 100) / 9;
      objectifGlucidesGrammes = (caloriesObjectif * objectifGlucides / 100) / 4;
      proteinesParKg = objectifProteinesGrammes / poids;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poids': poids,
      'taille': taille,
      'age': age,
      'sexe': sexe,
      'niveauActivite': niveauActivite,
      'objectif': objectif,
      'objectifProteines': objectifProteines,
      'objectifLipides': objectifLipides,
      'objectifGlucides': objectifGlucides,
      'proteinesParKg': proteinesParKg,
    };
  }

  factory ParametresNutritionnels.fromMap(Map<String, dynamic> map) {
    final params = ParametresNutritionnels(
      id: map['id'],
      poids: (map['poids'] as num).toDouble(),
      taille: (map['taille'] as num).toDouble(),
      age: map['age'] as int,
      sexe: map['sexe'] as String,
      niveauActivite: map['niveauActivite'] as String,
      objectif: map['objectif'] as String? ?? 'maintien',
      objectifProteines: (map['objectifProteines'] as num).toDouble(),
      objectifLipides: (map['objectifLipides'] as num).toDouble(),
      objectifGlucides: (map['objectifGlucides'] as num).toDouble(),
    );
    params.proteinesParKg = (map['proteinesParKg'] as num?)?.toDouble() ?? 1.6;
    params.calculerBesoins(objectif: params.objectif);
    return params;
  }
} 
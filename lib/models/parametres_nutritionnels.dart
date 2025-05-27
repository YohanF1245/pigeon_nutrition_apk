class ParametresNutritionnels {
  String id;
  // Données physiques
  double poids; // en kg
  double taille; // en cm
  int age;
  String sexe; // 'homme' ou 'femme'
  String niveauActivite; // 'sedentaire', 'leger', 'modere', 'intense', 'tres_intense'

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

  ParametresNutritionnels({
    required this.id,
    required this.poids,
    required this.taille,
    required this.age,
    required this.sexe,
    required this.niveauActivite,
    this.objectifProteines = 30,
    this.objectifLipides = 25,
    this.objectifGlucides = 45,
  }) {
    calculerBesoins();
  }

  void calculerBesoins() {
    // Calcul du TMB selon la formule de Mifflin-St Jeor
    if (sexe == 'homme') {
      tmb = (10 * poids) + (6.25 * taille) - (5 * age) + 5;
    } else {
      tmb = (10 * poids) + (6.25 * taille) - (5 * age) - 161;
    }

    // Facteur d'activité
    double facteurActivite = switch (niveauActivite) {
      'sedentaire' => 1.2,
      'leger' => 1.375,
      'modere' => 1.55,
      'intense' => 1.725,
      'tres_intense' => 1.9,
      _ => 1.2,
    };

    // Calcul des calories quotidiennes
    caloriesQuotidiennes = tmb * facteurActivite;

    // Calcul des macronutriments en grammes
    // Protéines et glucides = 4 calories/g, Lipides = 9 calories/g
    objectifProteinesGrammes = (caloriesQuotidiennes * (objectifProteines / 100)) / 4;
    objectifLipidesGrammes = (caloriesQuotidiennes * (objectifLipides / 100)) / 9;
    objectifGlucidesGrammes = (caloriesQuotidiennes * (objectifGlucides / 100)) / 4;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poids': poids,
      'taille': taille,
      'age': age,
      'sexe': sexe,
      'niveauActivite': niveauActivite,
      'objectifProteines': objectifProteines,
      'objectifLipides': objectifLipides,
      'objectifGlucides': objectifGlucides,
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
      objectifProteines: (map['objectifProteines'] as num).toDouble(),
      objectifLipides: (map['objectifLipides'] as num).toDouble(),
      objectifGlucides: (map['objectifGlucides'] as num).toDouble(),
    );
    params.calculerBesoins();
    return params;
  }
} 
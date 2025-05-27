class Aliment {
  String id;
  String nom;
  String description;
  bool gestionStock;
  double quantiteStock;
  double seuilAlerte;
  String unite; // 'g', 'ml'
  String? uniteSecondaire; // ex: "œuf", "tranche"
  double? facteurConversion; // ex: 1 œuf = 50g
  double quantiteAchatParDefaut;
  double? decrementationJournaliere; // Quantité à décrémenter automatiquement par jour
  
  // Valeurs nutritionnelles pour 100g/100ml
  double calories;
  double proteines;
  double lipides;
  double glucides;
  double fibres;
  double eau;

  // Prix
  double prixUnitaire;
  String devise; // 'EUR', 'USD', etc.

  Aliment({
    required this.id,
    required this.nom,
    this.description = '',
    this.gestionStock = false,
    required this.quantiteStock,
    required this.seuilAlerte,
    required this.unite,
    this.uniteSecondaire,
    this.facteurConversion,
    required this.quantiteAchatParDefaut,
    this.decrementationJournaliere,
    required this.calories,
    required this.proteines,
    required this.lipides,
    required this.glucides,
    this.fibres = 0,
    this.eau = 0,
    required this.prixUnitaire,
    this.devise = 'EUR',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'gestionStock': gestionStock ? 1 : 0,
      'quantiteStock': quantiteStock,
      'seuilAlerte': seuilAlerte,
      'unite': unite,
      'uniteSecondaire': uniteSecondaire,
      'facteurConversion': facteurConversion,
      'quantiteAchatParDefaut': quantiteAchatParDefaut,
      'decrementationJournaliere': decrementationJournaliere,
      'calories': calories,
      'proteines': proteines,
      'lipides': lipides,
      'glucides': glucides,
      'fibres': fibres,
      'eau': eau,
      'prixUnitaire': prixUnitaire,
      'devise': devise,
    };
  }

  factory Aliment.fromMap(Map<String, dynamic> map) {
    return Aliment(
      id: map['id'],
      nom: map['nom'],
      description: map['description'] ?? '',
      gestionStock: map['gestionStock'] == 1,
      quantiteStock: map['quantiteStock'].toDouble(),
      seuilAlerte: map['seuilAlerte'].toDouble(),
      unite: map['unite'],
      uniteSecondaire: map['uniteSecondaire'],
      facteurConversion: map['facteurConversion']?.toDouble(),
      quantiteAchatParDefaut: map['quantiteAchatParDefaut'].toDouble(),
      decrementationJournaliere: map['decrementationJournaliere']?.toDouble(),
      calories: map['calories'].toDouble(),
      proteines: map['proteines'].toDouble(),
      lipides: map['lipides'].toDouble(),
      glucides: map['glucides'].toDouble(),
      fibres: map['fibres']?.toDouble() ?? 0,
      eau: map['eau']?.toDouble() ?? 0,
      prixUnitaire: map['prixUnitaire'].toDouble(),
      devise: map['devise'] ?? 'EUR',
    );
  }

  // Méthode pour convertir une quantité de l'unité secondaire vers l'unité principale
  double convertirEnUnitePrincipale(double quantiteUniteSecondaire) {
    if (uniteSecondaire == null || facteurConversion == null) return quantiteUniteSecondaire;
    return quantiteUniteSecondaire * facteurConversion!;
  }

  // Méthode pour convertir une quantité de l'unité principale vers l'unité secondaire
  double convertirEnUniteSecondaire(double quantiteUnitePrincipale) {
    if (uniteSecondaire == null || facteurConversion == null) return quantiteUnitePrincipale;
    return quantiteUnitePrincipale / facteurConversion!;
  }

  // Méthode pour mettre à jour le stock
  void ajusterStock(double quantite) {
    quantiteStock += quantite;
    if (quantiteStock < 0) quantiteStock = 0;
  }

  // Vérifier si le stock est bas
  bool get stockBas => gestionStock && quantiteStock <= seuilAlerte;

  // Calculer le prix pour une quantité donnée
  double calculerPrix(double quantite) {
    return (prixUnitaire * quantite) / 100; // Prix pour 100g/ml
  }

  // Calculer les valeurs nutritionnelles pour une quantité donnée
  Map<String, double> calculerNutriments(double quantite) {
    double facteur = quantite / 100; // Les valeurs sont pour 100g/ml
    return {
      'calories': calories * facteur,
      'proteines': proteines * facteur,
      'lipides': lipides * facteur,
      'glucides': glucides * facteur,
      'fibres': fibres * facteur,
      'eau': eau * facteur,
    };
  }
} 
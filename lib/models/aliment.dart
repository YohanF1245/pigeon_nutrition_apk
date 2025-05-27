import 'package:uuid/uuid.dart';
import 'unite_base.dart';

class Aliment {
  final String id;
  final String nom;
  final UniteBase unite;
  final String? uniteSecondaire;
  final double prixUnitaire;
  final String devise;
  final bool gestionStock;
  double quantiteStock; // Non final pour permettre la mise à jour du stock
  final double? seuilAlerte;
  final double? decrementationJournaliere;
  final double quantiteAchatParDefaut;
  final double calories;
  final double proteines;
  final double lipides;
  final double glucides;
  final double? facteurConversion;

  Aliment({
    required this.id,
    required this.nom,
    required this.unite,
    this.uniteSecondaire,
    required this.prixUnitaire,
    required this.devise,
    required this.gestionStock,
    required this.quantiteStock,
    this.seuilAlerte,
    this.decrementationJournaliere,
    this.quantiteAchatParDefaut = 1000,
    this.calories = 0,
    this.proteines = 0,
    this.lipides = 0,
    this.glucides = 0,
    this.facteurConversion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'unite': unite.symbole,
      'uniteSecondaire': uniteSecondaire,
      'prixUnitaire': prixUnitaire,
      'devise': devise,
      'gestionStock': gestionStock ? 1 : 0,
      'quantiteStock': quantiteStock,
      'seuilAlerte': seuilAlerte,
      'decrementationJournaliere': decrementationJournaliere,
      'quantiteAchatParDefaut': quantiteAchatParDefaut,
      'calories': calories,
      'proteines': proteines,
      'lipides': lipides,
      'glucides': glucides,
      'facteurConversion': facteurConversion,
    };
  }

  factory Aliment.fromMap(Map<String, dynamic> map) {
    return Aliment(
      id: map['id'] as String,
      nom: map['nom'] as String,
      unite: UniteBase.fromSymbole(map['unite'] as String),
      uniteSecondaire: map['uniteSecondaire'] as String?,
      prixUnitaire: (map['prixUnitaire'] as num).toDouble(),
      devise: map['devise'] as String,
      gestionStock: map['gestionStock'] == 1,
      quantiteStock: (map['quantiteStock'] as num).toDouble(),
      seuilAlerte: map['seuilAlerte'] == null ? null : (map['seuilAlerte'] as num).toDouble(),
      decrementationJournaliere: map['decrementationJournaliere'] == null ? null : (map['decrementationJournaliere'] as num).toDouble(),
      quantiteAchatParDefaut: (map['quantiteAchatParDefaut'] as num?)?.toDouble() ?? 1000,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      proteines: (map['proteines'] as num?)?.toDouble() ?? 0,
      lipides: (map['lipides'] as num?)?.toDouble() ?? 0,
      glucides: (map['glucides'] as num?)?.toDouble() ?? 0,
      facteurConversion: map['facteurConversion'] == null ? null : (map['facteurConversion'] as num).toDouble(),
    );
  }

  Aliment copyWith({
    String? id,
    String? nom,
    UniteBase? unite,
    String? uniteSecondaire,
    double? prixUnitaire,
    String? devise,
    bool? gestionStock,
    double? quantiteStock,
    double? seuilAlerte,
    double? decrementationJournaliere,
    double? quantiteAchatParDefaut,
    double? calories,
    double? proteines,
    double? lipides,
    double? glucides,
    double? facteurConversion,
  }) {
    return Aliment(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      unite: unite ?? this.unite,
      uniteSecondaire: uniteSecondaire ?? this.uniteSecondaire,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      devise: devise ?? this.devise,
      gestionStock: gestionStock ?? this.gestionStock,
      quantiteStock: quantiteStock ?? this.quantiteStock,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      decrementationJournaliere: decrementationJournaliere ?? this.decrementationJournaliere,
      quantiteAchatParDefaut: quantiteAchatParDefaut ?? this.quantiteAchatParDefaut,
      calories: calories ?? this.calories,
      proteines: proteines ?? this.proteines,
      lipides: lipides ?? this.lipides,
      glucides: glucides ?? this.glucides,
      facteurConversion: facteurConversion ?? this.facteurConversion,
    );
  }

  // Méthode pour mettre à jour le stock
  void ajusterStock(double quantite) {
    quantiteStock += quantite;
    if (quantiteStock < 0) quantiteStock = 0;
  }

  // Vérifier si le stock est bas
  bool get stockBas => gestionStock && seuilAlerte != null && quantiteStock <= seuilAlerte!;

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
    };
  }
} 
import 'package:uuid/uuid.dart';
import 'unite_base.dart';

class Aliment {
  final String id;
  final String nom;
  final UniteBase unite;
  final double prixUnitaire;
  final String devise;
  final bool gestionStock;
  double quantiteStock;
  final double? seuilAlerte;
  final double? decrementationJournaliere;
  final double quantiteAchatParDefaut;
  final double calories;
  final double proteines;
  final double lipides;
  final double glucides;
  final double? poidsUnitaire;
  final String? unitePortionLabel;
  final int? nombreUniteParLot;

  Aliment({
    required this.id,
    required this.nom,
    required this.unite,
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
    this.poidsUnitaire,
    this.unitePortionLabel,
    this.nombreUniteParLot,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'unite': unite.symbole,
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
      'poidsUnitaire': poidsUnitaire,
      'unitePortionLabel': unitePortionLabel,
      'nombreUniteParLot': nombreUniteParLot,
    };
  }

  factory Aliment.fromMap(Map<String, dynamic> map) {
    return Aliment(
      id: map['id'] as String,
      nom: map['nom'] as String,
      unite: UniteBase.fromSymbole(map['unite'] as String),
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
      poidsUnitaire: map['poidsUnitaire'] == null ? null : (map['poidsUnitaire'] as num).toDouble(),
      unitePortionLabel: map['unitePortionLabel'] as String?,
      nombreUniteParLot: map['nombreUniteParLot'] as int?,
    );
  }

  Aliment copyWith({
    String? id,
    String? nom,
    UniteBase? unite,
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
    double? poidsUnitaire,
    String? unitePortionLabel,
    int? nombreUniteParLot,
  }) {
    return Aliment(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      unite: unite ?? this.unite,
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
      poidsUnitaire: poidsUnitaire ?? this.poidsUnitaire,
      unitePortionLabel: unitePortionLabel ?? this.unitePortionLabel,
      nombreUniteParLot: nombreUniteParLot ?? this.nombreUniteParLot,
    );
  }

  // Nouvelles méthodes pour la gestion des portions
  double get stockEnUnites {
    // Le stock est déjà en unités si on a une unité de portion
    if (unitePortionLabel != null) return quantiteStock;
    return quantiteStock;
  }

  String getStockDisplay() {
    if (unitePortionLabel != null) {
      return '${quantiteStock.toStringAsFixed(0)} ${unitePortionLabel!}';
    }
    return '${quantiteStock.toStringAsFixed(1)} ${unite.symbole}';
  }

  String getStockLabel() {
    if (!gestionStock) return '';
    if (unitePortionLabel != null) {
      return 'Stock (en ${unitePortionLabel!.toLowerCase()})';
    }
    return 'Stock (en ${unite.symbole})';
  }

  // Vérifier si le stock est bas
  bool get stockBas {
    if (!gestionStock || seuilAlerte == null) return false;
    return quantiteStock <= seuilAlerte!;
  }

  // Méthode pour mettre à jour le stock
  void ajusterStock(double quantite) {
    quantiteStock += quantite;
    if (quantiteStock < 0) quantiteStock = 0;
  }

  // Calculer les valeurs nutritionnelles pour une quantité donnée
  Map<String, double> calculerNutriments(double quantite) {
    if (poidsUnitaire != null && unitePortionLabel != null) {
      // Si on a une unité de portion, on convertit d'abord en grammes
      double quantiteEnGrammes = quantite * poidsUnitaire!;
      double facteur = quantiteEnGrammes / 100;
      return {
        'calories': calories * facteur,
        'proteines': proteines * facteur,
        'lipides': lipides * facteur,
        'glucides': glucides * facteur,
      };
    }
    // Sinon on utilise directement la quantité
    double facteur = quantite / 100;
    return {
      'calories': calories * facteur,
      'proteines': proteines * facteur,
      'lipides': lipides * facteur,
      'glucides': glucides * facteur,
    };
  }

  // Calculer le prix pour une quantité donnée
  double calculerPrix(double quantite) {
    if (poidsUnitaire != null && poidsUnitaire! > 0) {
      return (prixUnitaire * quantite * poidsUnitaire!) / 100; // Prix pour 100g/ml
    }
    return (prixUnitaire * quantite) / 100; // Prix pour 100g/ml
  }

  // Méthode pour calculer les nutriments par portion
  Map<String, double> calculerNutrimentsParPortion() {
    if (poidsUnitaire == null || poidsUnitaire == 0) {
      return calculerNutriments(100); // Retourne pour 100g si pas de portion définie
    }
    return calculerNutriments(poidsUnitaire!);
  }

  // Méthode pour ajuster le stock en unités
  void ajusterStockEnUnites(double nombreUnites) {
    if (poidsUnitaire != null && poidsUnitaire! > 0) {
      ajusterStock(nombreUnites * poidsUnitaire!);
    } else {
      ajusterStock(nombreUnites);
    }
  }
} 
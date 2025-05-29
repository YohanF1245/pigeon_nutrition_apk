import 'package:flutter/material.dart';
import '../models/repas.dart';
import '../models/aliment.dart';
import '../services/storage_service.dart';
import '../services/aliment_service.dart';
import 'package:intl/intl.dart';
import 'ajouter_repas_screen.dart';
import '../models/unite_base.dart';
import '../models/parametres_nutritionnels.dart';

class RepasScreen extends StatefulWidget {
  const RepasScreen({super.key});

  @override
  State<RepasScreen> createState() => _RepasScreenState();
}

class _RepasScreenState extends State<RepasScreen> {
  final StorageService _storageService = StorageService();
  final AlimentService _alimentService = AlimentService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = AppBar().preferredSize.height;
    final bottomNavBarHeight = kBottomNavigationBarHeight;
    final floatingActionButtonHeight = 56.0;
    final floatingActionButtonMargin = 16.0;
    
    final totalHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    
    final availableHeight = totalHeight - 
        appBarHeight - 
        bottomNavBarHeight - 
        topPadding - 
        bottomPadding - 
        floatingActionButtonHeight -
        floatingActionButtonMargin;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Section des macronutriments (10% de la hauteur disponible)
            Container(
              height: availableHeight * 0.1,
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: _buildMacronutrientsSection(),
            ),
            
            // Section de l'agenda (70% de la hauteur disponible)
            Container(
              height: availableHeight * 0.7,
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: _buildAgendaSection(),
            ),
            
            // Section de la liste des repas (20% de la hauteur disponible)
            Container(
              height: availableHeight * 0.2,
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: _buildMealListSection(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterRepas,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMacronutrientsSection() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _calculerNutrimentsJour(_selectedDate),
        _storageService.getParametresNutritionnels(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final nutriments = snapshot.data?[0] as Map<String, double>? ?? {
          'calories': 0.0,
          'proteines': 0.0,
          'lipides': 0.0,
          'glucides': 0.0,
        };

        final parametres = snapshot.data?[1];
        final objectifs = {
          'calories': parametres?.caloriesQuotidiennes ?? 2000.0,
          'proteines': parametres?.objectifProteinesGrammes ?? 150.0,
          'lipides': parametres?.objectifLipidesGrammes ?? 70.0,
          'glucides': parametres?.objectifGlucidesGrammes ?? 250.0,
        };

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrimentBox('Calories', nutriments['calories']!, objectifs['calories']!, 'kcal', Colors.blue),
                _buildNutrimentBox('Protéines', nutriments['proteines']!, objectifs['proteines']!, 'g', Colors.red),
                _buildNutrimentBox('Lipides', nutriments['lipides']!, objectifs['lipides']!, 'g', Colors.orange),
                _buildNutrimentBox('Glucides', nutriments['glucides']!, objectifs['glucides']!, 'g', Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutrimentBox(String label, double value, double objectif, String unit, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: value.toStringAsFixed(0),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '/${objectif.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaSection() {
    return Card(
      child: Column(
        children: [
          // En-tête avec la date sélectionnée et les boutons de navigation
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),
          // Grille horaire
          Expanded(
            child: ListView.builder(
              itemCount: 24,
              itemBuilder: (context, hour) {
                return Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          '$hour:00',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: DragTarget<Repas>(
                          onAccept: (repas) {
                            // TODO: Implémenter la logique de placement du repas
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              color: candidateData.isNotEmpty
                                  ? Colors.grey[200]
                                  : Colors.transparent,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealListSection() {
    final ScrollController scrollController = ScrollController();

    void _scrollLeft() {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.offset - 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    void _scrollRight() {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.offset + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    return FutureBuilder<List<Repas>>(
      future: _storageService.getRepas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final repas = snapshot.data ?? [];

        return Card(
          child: Column(
            children: [
              // En-tête avec titre et flèches
              SizedBox(
                height: 40, // Hauteur réduite pour l'en-tête
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _scrollLeft,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const Expanded(
                      child: Text(
                        'Repas disponibles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _scrollRight,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              // Liste des repas
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: repas.length,
                  itemBuilder: (context, index) {
                    final repasItem = repas[index];
                    return Draggable<Repas>(
                      data: repasItem,
                      feedback: Material(
                        elevation: 4.0,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.white,
                          child: Text(repasItem.nom),
                        ),
                      ),
                      childWhenDragging: Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.grey[200],
                        child: Text(repasItem.nom),
                      ),
                      child: FutureBuilder<List<Aliment>>(
                        future: _alimentService.getAllAliments(),
                        builder: (context, alimentsSnapshot) {
                          if (!alimentsSnapshot.hasData) {
                            return const Card(
                              margin: EdgeInsets.symmetric(horizontal: 4.0),
                              child: SizedBox(
                                width: 140,
                                height: double.infinity,
                                child: Center(
                                  child: Text('Chargement...'),
                                ),
                              ),
                            );
                          }

                          return FutureBuilder<Map<String, double>>(
                            future: repasItem.calculerNutriments(alimentsSnapshot.data!),
                            builder: (context, nutrimentSnapshot) {
                              if (!nutrimentSnapshot.hasData) {
                                return const Card(
                                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                                  child: SizedBox(
                                    width: 140,
                                    height: double.infinity,
                                    child: Center(
                                      child: Text('Calcul des nutriments...'),
                                    ),
                                  ),
                                );
                              }
                              final nutriments = nutrimentSnapshot.data!;
                              return Card(
                                margin: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 8.0),
                                child: GestureDetector(
                                  onTap: () => _afficherDetailsRepas(context, repasItem, alimentsSnapshot.data!),
                                  child: Container(
                                    width: 140,
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          repasItem.nom,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: DefaultTextStyle.of(context).style.copyWith(
                                                  fontSize: 12,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Cal : ',
                                                    style: TextStyle(color: Colors.blue),
                                                  ),
                                                  TextSpan(
                                                    text: nutriments['calories']?.toStringAsFixed(0),
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                style: DefaultTextStyle.of(context).style.copyWith(
                                                  fontSize: 12,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Prot : ',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                  TextSpan(
                                                    text: '${nutriments['proteines']?.toStringAsFixed(0)} g',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: DefaultTextStyle.of(context).style.copyWith(
                                                  fontSize: 12,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Lip : ',
                                                    style: TextStyle(color: Colors.orange),
                                                  ),
                                                  TextSpan(
                                                    text: '${nutriments['lipides']?.toStringAsFixed(0)} g',
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                style: DefaultTextStyle.of(context).style.copyWith(
                                                  fontSize: 12,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Gluc : ',
                                                    style: TextStyle(color: Colors.green),
                                                  ),
                                                  TextSpan(
                                                    text: '${nutriments['glucides']?.toStringAsFixed(0)} g',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _ajouterRepas() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AjouterRepasScreen(),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<Map<String, double>> _calculerNutrimentsJour(DateTime date) async {
    final repas = await _storageService.getRepas();
    final repasJour = repas.where((r) => 
      r.dateHeure.year == date.year && 
      r.dateHeure.month == date.month && 
      r.dateHeure.day == date.day
    ).toList();

    double calories = 0;
    double proteines = 0;
    double lipides = 0;
    double glucides = 0;

    final aliments = await _alimentService.getAllAliments();

    for (final repas in repasJour) {
      final nutriments = await repas.calculerNutriments(aliments);
      calories += nutriments['calories'] ?? 0;
      proteines += nutriments['proteines'] ?? 0;
      lipides += nutriments['lipides'] ?? 0;
      glucides += nutriments['glucides'] ?? 0;
    }

    return {
      'calories': calories,
      'proteines': proteines,
      'lipides': lipides,
      'glucides': glucides,
    };
  }

  void _afficherDetailsRepas(BuildContext context, Repas repas, List<Aliment> aliments) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      repas.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AjouterRepasScreen(repasAModifier: repas),
                            ),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirme = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: const Text('Voulez-vous vraiment supprimer ce repas ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirme == true) {
                            await _storageService.deleteRepas(repas.id);
                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {});
                            }
                          }
                        },
                        tooltip: 'Supprimer',
                        color: Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                'Date : ${_dateFormat.format(repas.dateHeure)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              const Text(
                'Aliments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: repas.aliments.length,
                  itemBuilder: (context, index) {
                    final repasAliment = repas.aliments[index];
                    final aliment = aliments.firstWhere(
                      (a) => a.id == repasAliment.alimentId,
                      orElse: () => Aliment(
                        id: '',
                        nom: 'Aliment inconnu',
                        unite: UniteBase.gramme,
                        prixUnitaire: 0,
                        devise: '€',
                        gestionStock: false,
                        quantiteStock: 0,
                        calories: 0,
                        proteines: 0,
                        lipides: 0,
                        glucides: 0,
                      ),
                    );

                    String quantiteAffichee;
                    if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null && aliment.poidsUnitaire! > 0) {
                      final portions = repasAliment.quantite / aliment.poidsUnitaire!;
                      quantiteAffichee = '${portions.toStringAsFixed(1)} ${aliment.unitePortionLabel}${portions > 1 ? 's' : ''} (${repasAliment.quantite.toStringAsFixed(1)}g)';
                    } else {
                      quantiteAffichee = '${repasAliment.quantite.toStringAsFixed(1)}g';
                    }

                    final ratio = repasAliment.quantite / 100;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16.0, 4.0, 8.0, 0.0),
                            title: Text(
                              aliment.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(quantiteAffichee),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  aliment.nom,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () => Navigator.of(context).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            quantiteAffichee,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          _buildNutrimentDetail('Calories', aliment.calories * ratio, 'kcal', Colors.blue),
                                          _buildNutrimentDetail('Protéines', aliment.proteines * ratio, 'g', Colors.red),
                                          _buildNutrimentDetail('Lipides', aliment.lipides * ratio, 'g', Colors.orange),
                                          _buildNutrimentDetail('Glucides', aliment.glucides * ratio, 'g', Colors.green),
                                          const Divider(height: 32),
                                          FutureBuilder<ParametresNutritionnels?>(
                                            future: _storageService.getParametresNutritionnels(),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const SizedBox.shrink();
                                              }

                                              final objectifs = snapshot.data!;
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Pourcentage des objectifs journaliers',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children: [
                                                      _buildPourcentageObjectif('Calories', aliment.calories * ratio, objectifs.caloriesQuotidiennes, Colors.blue),
                                                      _buildPourcentageObjectif('Protéines', aliment.proteines * ratio, objectifs.objectifProteinesGrammes, Colors.red),
                                                      _buildPourcentageObjectif('Lipides', aliment.lipides * ratio, objectifs.objectifLipidesGrammes, Colors.orange),
                                                      _buildPourcentageObjectif('Glucides', aliment.glucides * ratio, objectifs.objectifGlucidesGrammes, Colors.green),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 11),
                                    children: [
                                      TextSpan(
                                        text: '${(aliment.calories * ratio).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: ' kcal'),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 11),
                                    children: [
                                      TextSpan(
                                        text: '${(aliment.proteines * ratio).toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: 'P '),
                                      TextSpan(
                                        text: '${(aliment.lipides * ratio).toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: 'L '),
                                      TextSpan(
                                        text: '${(aliment.glucides * ratio).toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: 'G'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              FutureBuilder<Map<String, double>>(
                future: repas.calculerNutriments(aliments),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final nutriments = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrimentTotal('Calories', nutriments['calories']!, 'kcal', Colors.blue),
                          _buildNutrimentTotal('Protéines', nutriments['proteines']!, 'g', Colors.red),
                          _buildNutrimentTotal('Lipides', nutriments['lipides']!, 'g', Colors.orange),
                          _buildNutrimentTotal('Glucides', nutriments['glucides']!, 'g', Colors.green),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<ParametresNutritionnels?>(
                        future: _storageService.getParametresNutritionnels(),
                        builder: (context, objectifsSnapshot) {
                          if (!objectifsSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final objectifs = objectifsSnapshot.data!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPourcentageObjectif('Calories', nutriments['calories']!, objectifs.caloriesQuotidiennes, Colors.blue),
                              _buildPourcentageObjectif('Protéines', nutriments['proteines']!, objectifs.objectifProteinesGrammes, Colors.red),
                              _buildPourcentageObjectif('Lipides', nutriments['lipides']!, objectifs.objectifLipidesGrammes, Colors.orange),
                              _buildPourcentageObjectif('Glucides', nutriments['glucides']!, objectifs.objectifGlucidesGrammes, Colors.green),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrimentDetail(String label, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPourcentageNutriment(String label, double calories, double totalCalories, Color color) {
    final pourcentage = totalCalories > 0 ? (calories / totalCalories * 100).round() : 0;
    return Column(
      children: [
        Text(
          '$label',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$pourcentage%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNutrimentTotal(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPourcentageObjectif(String label, double valeur, double objectif, Color color) {
    final pourcentage = (valeur / objectif * 100).round();
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$pourcentage%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: pourcentage > 100 ? Colors.red : color,
          ),
        ),
      ],
    );
  }
} 
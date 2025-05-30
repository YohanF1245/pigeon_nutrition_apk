import 'package:flutter/material.dart';
import '../models/repas.dart';
import '../models/aliment.dart';
import '../models/jour_repas.dart';
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
  bool _isRepasExpanded = false;

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
            
            // Section de l'agenda (90% ou 45% selon l'état)
            Container(
              height: availableHeight * (_isRepasExpanded ? 0.45 : 0.8),
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: _buildAgendaSection(),
            ),
            
            // Section de la liste des repas (10% ou 45% selon l'état)
            Container(
              height: availableHeight * (_isRepasExpanded ? 0.45 : 0.1),
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

        final nutriments = (snapshot.data?[0] as Map<String, double>?) ?? {
          'calories': 0.0,
          'proteines': 0.0,
          'lipides': 0.0,
          'glucides': 0.0,
        };

        final parametres = snapshot.data?[1] as ParametresNutritionnels?;
        final objectifs = {
          'calories': parametres?.caloriesQuotidiennes ?? 2000.0,
          'proteines': parametres?.objectifProteinesGrammes ?? 150.0,
          'lipides': parametres?.objectifLipidesGrammes ?? 70.0,
          'glucides': parametres?.objectifGlucidesGrammes ?? 250.0,
        };

        return GestureDetector(
          onTap: () => _afficherTableauNutriments(context, nutriments, objectifs),
          child: Card(
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
            child: FutureBuilder<Map<int, List<JourRepas>>>(
              future: _getJoursRepasParHeure(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final repasParHeure = snapshot.data ?? {};
                
                return ListView.builder(
                  itemCount: 18, // De 6h à 23h = 18 heures
                  itemBuilder: (context, index) {
                    final hour = index + 6; // Commencer à 6h
                    final joursRepas = repasParHeure[hour] ?? [];

                    return Container(
                      height: 30,
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
                          // Colonne des heures
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const VerticalDivider(),
                          // Zone des repas
                          Expanded(
                            child: Stack(
                              children: [
                                // Zone de drop
                                DragTarget<Repas>(
                                  onWillAccept: (repas) {
                                    if (repas == null) return false;
                                    return true;
                                  },
                                  onAcceptWithDetails: (details) async {
                                    final repas = details.data;
                                    final disponible = await _verifierDisponibiliteHoraire(hour);
                                    
                                    if (!disponible) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Il y a déjà un repas prévu à cette heure'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    
                                    final jourRepas = JourRepas(
                                      date: DateTime(
                                        _selectedDate.year,
                                        _selectedDate.month,
                                        _selectedDate.day,
                                      ),
                                      repasId: repas.id,
                                      heure: hour,
                                      minute: 0,
                                    );

                                    try {
                                      await _storageService.saveJourRepas(jourRepas);
                                      if (mounted) setState(() {});
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return Container(
                                      color: candidateData.isNotEmpty
                                          ? Colors.blue[100]?.withOpacity(0.3)
                                          : Colors.transparent,
                                    );
                                  },
                                ),
                                // Repas existants
                                ...joursRepas.map((jourRepas) => FutureBuilder<Repas?>(
                                  future: _getRepas(jourRepas.repasId),
                                  builder: (context, repasSnapshot) {
                                    if (!repasSnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    final repas = repasSnapshot.data!;
                                    return Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: GestureDetector(
                                          onTap: () async {
                                            final aliments = await _alimentService.getAllAliments();
                                            if (!mounted) return;
                                            
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) => Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(Icons.visibility),
                                                    title: const Text('Voir les détails'),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _afficherDetailsRepas(context, repas, aliments);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons.delete, color: Colors.red),
                                                    title: const Text('Retirer de l\'agenda', style: TextStyle(color: Colors.red)),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _confirmerSuppressionJourRepas(context, jourRepas);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: 26, // 30 - 2*2 (marges)
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    repas.nom,
                                                    style: const TextStyle(fontSize: 10),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 12,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<int, List<JourRepas>>> _getJoursRepasParHeure(DateTime date) async {
    final joursRepas = await _storageService.getJoursRepas(date: date);
    final Map<int, List<JourRepas>> repasParHeure = {};
    
    for (var jourRepas in joursRepas) {
      repasParHeure.putIfAbsent(jourRepas.heure, () => []).add(jourRepas);
    }
    
    return repasParHeure;
  }

  Future<Repas?> _getRepas(String id) async {
    final repas = await _storageService.getRepas();
    return repas.firstWhere((r) => r.id == id);
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

    return Card(
      child: Column(
        children: [
          // En-tête avec titre et flèches
          GestureDetector(
            onTap: () {
              setState(() {
                _isRepasExpanded = !_isRepasExpanded;
              });
            },
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    _isRepasExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
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
                  if (_isRepasExpanded) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _scrollLeft,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _scrollRight,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Liste des repas (visible uniquement si déplié)
          if (_isRepasExpanded)
            Expanded(
              child: FutureBuilder<List<Repas>>(
                future: _storageService.getRepas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final repas = snapshot.data ?? [];

                  return ListView.builder(
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
                                    onTap: () async {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) => Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.visibility),
                                              title: const Text('Voir les détails'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _afficherDetailsRepas(context, repasItem, alimentsSnapshot.data!);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.edit),
                                              title: const Text('Modifier'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _modifierRepas(context, repasItem);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.delete, color: Colors.red),
                                              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _confirmerSuppressionRepas(context, repasItem, alimentsSnapshot.data!);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
                  );
                },
              ),
            ),
        ],
      ),
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
    // On crée une date de début à minuit
    final debut = DateTime(date.year, date.month, date.day);
    // On crée une date de fin à minuit le jour suivant
    final fin = DateTime(date.year, date.month, date.day + 1);
    
    final joursRepas = await _storageService.getJoursRepas(date: date);
    final repas = await _storageService.getRepas();
    final repasJour = joursRepas.map((jr) => 
      repas.firstWhere((r) => r.id == jr.repasId)
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
              Text(
                'Date : ${_dateFormat.format(repas.createdAt!)}',
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
                        id: repasAliment.alimentId,
                        nom: 'Aliment supprimé',
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
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        title: Text(
                          aliment.nom,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: aliment.nom == 'Aliment supprimé' ? Colors.red : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quantiteAffichee),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(aliment.calories * ratio).toStringAsFixed(0)} kcal',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                                Text(
                                  'P: ${(aliment.proteines * ratio).toStringAsFixed(1)}g',
                                  style: const TextStyle(color: Colors.red),
                                ),
                                Text(
                                  'L: ${(aliment.lipides * ratio).toStringAsFixed(1)}g',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                                Text(
                                  'G: ${(aliment.glucides * ratio).toStringAsFixed(1)}g',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              _buildNutrimentsCard(repas, aliments),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrimentsCard(Repas repas, List<Aliment> aliments) {
    return FutureBuilder<Map<String, double>>(
      future: repas.calculerNutriments(aliments),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final nutriments = snapshot.data!;
        return Column(
          children: [
            const Text(
              'Impact nutritionnel :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Calories', style: TextStyle(color: Colors.blue)),
                    Text(
                      '${nutriments['calories']?.toStringAsFixed(0)} kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Protéines', style: TextStyle(color: Colors.red)),
                    Text(
                      '${nutriments['proteines']?.toStringAsFixed(1)}g',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Lipides', style: TextStyle(color: Colors.orange)),
                    Text(
                      '${nutriments['lipides']?.toStringAsFixed(1)}g',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Glucides', style: TextStyle(color: Colors.green)),
                    Text(
                      '${nutriments['glucides']?.toStringAsFixed(1)}g',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmerSuppressionJourRepas(BuildContext context, JourRepas jourRepas) async {
    final repas = await _getRepas(jourRepas.repasId);
    if (repas == null) return;

    final aliments = await _alimentService.getAllAliments();
    if (!context.mounted) return;
    
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le repas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment retirer "${repas.nom}" de cette plage horaire ?'),
            const SizedBox(height: 8),
            _buildNutrimentsCard(repas, aliments),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _storageService.deleteJourRepas(jourRepas.id);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<bool> _verifierDisponibiliteHoraire(int heure) async {
    final joursRepas = await _storageService.getJoursRepas(date: _selectedDate);
    return !joursRepas.any((jr) => 
      jr.heure == heure && 
      (jr.minute >= 0 && jr.minute < 60)
    );
  }

  Future<void> _confirmerSuppressionRepas(BuildContext context, Repas repas, List<Aliment> aliments) async {
    final joursRepas = await _storageService.getJoursRepas();
    final joursRepasAffectes = joursRepas.where((jr) => jr.repasId == repas.id).toList();
    
    final nutriments = await repas.calculerNutriments(aliments);
    
    if (!context.mounted) return;
    
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le repas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer "${repas.nom}" ?'),
            if (joursRepasAffectes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Attention : Ce repas est utilisé ${joursRepasAffectes.length} fois dans l\'agenda.',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La suppression de ce repas l\'effacera également de l\'agenda.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 16),
            _buildNutrimentsCard(repas, aliments),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _storageService.deleteRepas(repas.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repas supprimé avec succès'),
          ),
        );
      }
    }
  }

  Future<void> _modifierRepas(BuildContext context, Repas repas) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterRepasScreen(
          repasAModifier: repas,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _afficherTableauNutriments(BuildContext context, Map<String, double> nutriments, Map<String, double> objectifs) async {
    final joursRepas = await _storageService.getJoursRepas(date: _selectedDate);
    final repas = await _storageService.getRepas();
    final aliments = await _alimentService.getAllAliments();
    
    final repasDuJour = joursRepas.map((jr) => 
      repas.firstWhere((r) => r.id == jr.repasId)
    ).toList();

    // Calculer les nutriments pour chaque repas
    final List<Map<String, double>> nutrimentsRepas = [];
    for (var repas in repasDuJour) {
      final nutr = await repas.calculerNutriments(aliments);
      nutrimentsRepas.add(nutr);
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Détail des repas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Text(
                'Date : ${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: const {
                      0: FlexColumnWidth(2), // Nom du repas
                      1: FlexColumnWidth(1), // Calories
                      2: FlexColumnWidth(1), // Protéines
                      3: FlexColumnWidth(1), // Lipides
                      4: FlexColumnWidth(1), // Glucides
                    },
                    children: [
                      // En-tête
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Repas', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Calories', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Protéines', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Lipides', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Glucides', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                      ),
                      // Lignes des repas
                      ...List.generate(repasDuJour.length, (index) {
                        final repas = repasDuJour[index];
                        final nutr = nutrimentsRepas[index];
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(repas.nom),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${nutr['calories']?.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.blue)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${nutr['proteines']?.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.red)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${nutr['lipides']?.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.orange)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${nutr['glucides']?.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.green)),
                            ),
                          ],
                        );
                      }),
                      // Ligne de séparation
                      const TableRow(
                        children: [
                          Divider(),
                          Divider(),
                          Divider(),
                          Divider(),
                          Divider(),
                        ],
                      ),
                      // Ligne des totaux
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${nutriments['calories']?.toStringAsFixed(0)} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${nutriments['proteines']?.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${nutriments['lipides']?.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${nutriments['glucides']?.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      // Ligne des objectifs
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[50]),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('OBJECTIF', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${objectifs['calories']?.toStringAsFixed(0)} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${objectifs['proteines']?.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${objectifs['lipides']?.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${objectifs['glucides']?.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
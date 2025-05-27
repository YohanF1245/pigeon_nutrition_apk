import 'package:flutter/material.dart';
import '../services/aliment_service.dart';
import '../services/storage_service.dart';
import '../models/parametres_nutritionnels.dart';
import '../models/repas.dart';
import 'parametres_nutritionnels_screen.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AlimentService _alimentService = AlimentService();
  final StorageService _storageService = StorageService();
  final _refreshController = StreamController<void>.broadcast();

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void refresh() {
    if (mounted) {
      setState(() {
        _refreshController.add(null);
      });
    }
  }

  Future<Map<String, double>> _calculerMacrosJour() async {
    final repas = await _storageService.getRepas();
    final aujourdhui = DateTime.now();
    final repasAujourdhui = repas.where((r) => 
      r.date.year == aujourdhui.year && 
      r.date.month == aujourdhui.month && 
      r.date.day == aujourdhui.day
    ).toList();

    double calories = 0;
    double proteines = 0;
    double lipides = 0;
    double glucides = 0;

    for (final repas in repasAujourdhui) {
      calories += repas.aliments.fold(0, (sum, a) {
        double facteur = a.quantite / 100;
        if (a.unite == 'kg') facteur *= 1000;
        return sum + (a.aliment.calories * facteur);
      });
      proteines += repas.totalProteines;
      lipides += repas.totalLipides;
      glucides += repas.totalGlucides;
    }

    return {
      'calories': calories,
      'proteines': proteines,
      'lipides': lipides,
      'glucides': glucides,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _alimentService.getAllAliments(),
        _alimentService.getAlimentsEnRupture(),
        _storageService.getParametresNutritionnels(),
        _calculerMacrosJour(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final aliments = snapshot.data?[0] ?? [];
        final alimentsEnRupture = snapshot.data?[1] ?? [];
        final parametres = snapshot.data?[2] as ParametresNutritionnels?;
        final macrosJour = snapshot.data?[3] as Map<String, double>? ?? {
          'calories': 0.0,
          'proteines': 0.0,
          'lipides': 0.0,
          'glucides': 0.0,
        };

        final macros = parametres != null ? {
          'Calories': {
            'actuel': macrosJour['calories'] ?? 0.0,
            'objectif': parametres.caloriesQuotidiennes,
            'unite': 'kcal'
          },
          'Protéines': {
            'actuel': macrosJour['proteines'] ?? 0.0,
            'objectif': parametres.objectifProteinesGrammes,
            'unite': 'g'
          },
          'Lipides': {
            'actuel': macrosJour['lipides'] ?? 0.0,
            'objectif': parametres.objectifLipidesGrammes,
            'unite': 'g'
          },
          'Glucides': {
            'actuel': macrosJour['glucides'] ?? 0.0,
            'objectif': parametres.objectifGlucidesGrammes,
            'unite': 'g'
          },
        } : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (macros != null) ...[
                // Section Macronutriments
                const Text(
                  'Macronutriments du Jour',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: macros.entries.map((entry) {
                        final nom = entry.key;
                        final actuel = entry.value['actuel'] as double;
                        final objectif = entry.value['objectif'] as double;
                        final unite = entry.value['unite'] as String;
                        final progress = (actuel / objectif).clamp(0.0, 1.0);

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(nom),
                                Text('${actuel.toStringAsFixed(1)}/${objectif.toStringAsFixed(1)} $unite'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              color: _getProgressColor(progress),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.settings,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Paramètres non configurés',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pour voir vos objectifs nutritionnels, veuillez configurer vos paramètres personnels.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (context) => const ParametresNutritionnelsScreen()),
                            );
                            if (result == true) {
                              setState(() {});
                            }
                          },
                          child: const Text('Configurer les paramètres'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Section Résumé
              const Text(
                'Résumé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.food_bank, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${aliments.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Aliments'),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.warning, size: 32, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text(
                            '${alimentsEnRupture.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text('Alertes'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return Colors.red;
    if (progress < 0.8) return Colors.orange;
    if (progress <= 1.0) return Colors.green;
    return Colors.red;
  }
} 
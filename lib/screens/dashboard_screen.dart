import 'package:flutter/material.dart';
import '../services/aliment_service.dart';
import '../services/storage_service.dart';
import '../models/parametres_nutritionnels.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AlimentService _alimentService = AlimentService();
  final StorageService _storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _alimentService.getAllAliments(),
        _alimentService.getAlimentsEnRupture(),
        _storageService.getParametresNutritionnels(),
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

        final macros = parametres != null ? {
          'Calories': {
            'actuel': 0.0, // TODO: Calculer depuis les repas du jour
            'objectif': parametres.caloriesQuotidiennes,
            'unite': 'kcal'
          },
          'Protéines': {
            'actuel': 0.0, // TODO: Calculer depuis les repas du jour
            'objectif': parametres.objectifProteinesGrammes,
            'unite': 'g'
          },
          'Lipides': {
            'actuel': 0.0, // TODO: Calculer depuis les repas du jour
            'objectif': parametres.objectifLipidesGrammes,
            'unite': 'g'
          },
          'Glucides': {
            'actuel': 0.0, // TODO: Calculer depuis les repas du jour
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
              ],

              // Section Alertes Stock
              if (alimentsEnRupture.isNotEmpty) ...[
                const Text(
                  'Alertes Stock',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.red[50],
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alimentsEnRupture.length,
                    itemBuilder: (context, index) {
                      final aliment = alimentsEnRupture[index];
                      return ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(aliment.nom),
                        subtitle: Text(
                          'Stock: ${aliment.quantiteStock} ${aliment.unite} (Seuil: ${aliment.seuilAlerte} ${aliment.unite})',
                        ),
                      );
                    },
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
    if (progress < 1.0) return Colors.green;
    return Colors.blue;
  }
} 
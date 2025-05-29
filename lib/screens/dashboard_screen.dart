import 'package:flutter/material.dart';
import '../services/aliment_service.dart';
import '../services/storage_service.dart';
import '../services/nutrition_history_service.dart';
import '../services/database_service.dart';
import '../models/parametres_nutritionnels.dart';
import '../models/repas.dart';
import '../models/aliment.dart';
import '../widgets/nutrition_delta_chart.dart';
import 'parametres_nutritionnels_screen.dart';
import 'dart:async';
import '../widgets/liste_courses.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final Function(List<dynamic>)? onAlimentsEnRuptureChanged;
  final DatabaseService databaseService;
  
  const DashboardScreen({
    super.key,
    this.onAlimentsEnRuptureChanged,
    required this.databaseService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AlimentService _alimentService = AlimentService();
  final StorageService _storageService = StorageService();
  late final NutritionHistoryService _nutritionHistoryService;
  final _refreshController = StreamController<void>.broadcast();
  
  List<Aliment>? _aliments;
  List<dynamic>? _alimentsEnRupture;
  ParametresNutritionnels? _parametres;
  Map<String, double>? _macrosJour;
  List<Map<String, dynamic>>? _nutritionHistory;
  bool _isLoading = true;
  String? _error;
  int _selectedPeriod = 7; // Période par défaut : 7 jours

  final List<Map<String, dynamic>> _periodOptions = [
    {'label': '7 jours', 'value': 7},
    {'label': '14 jours', 'value': 14},
    {'label': '30 jours', 'value': 30},
  ];

  @override
  void initState() {
    super.initState();
    _nutritionHistoryService = NutritionHistoryService(widget.databaseService);
    _loadData();
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aliments = await _alimentService.getAllAliments();
      final alimentsEnRupture = await _alimentService.getAlimentsEnRupture();
      final parametres = await _storageService.getParametresNutritionnels();
      final macrosJour = await _calculerMacrosJour();
      final nutritionHistory = await _nutritionHistoryService.getNutritionHistory(days: _selectedPeriod);

      if (!mounted) return;

      setState(() {
        _aliments = aliments;
        _alimentsEnRupture = alimentsEnRupture;
        _parametres = parametres;
        _macrosJour = macrosJour;
        _nutritionHistory = nutritionHistory;
        _isLoading = false;
      });

      widget.onAlimentsEnRuptureChanged?.call(alimentsEnRupture);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void refresh() {
    _loadData();
  }

  void _afficherListeCourses(BuildContext context, List<Aliment> alimentsEnRupture) {
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
                    'Liste de courses',
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
              Expanded(
                child: ListeCourses(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, double>> _calculerMacrosJour() async {
    try {
      final joursRepas = await _storageService.getJoursRepas(date: DateTime.now());
      final repas = await _storageService.getRepas();
      final repasAujourdhui = joursRepas.map((jr) => 
        repas.firstWhere((r) => r.id == jr.repasId)
      ).toList();

      double calories = 0;
      double proteines = 0;
      double lipides = 0;
      double glucides = 0;

      final aliments = await _alimentService.getAllAliments();

      for (final repas in repasAujourdhui) {
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
    } catch (e) {
      debugPrint('Erreur lors du calcul des macros: $e');
      return {
        'calories': 0,
        'proteines': 0,
        'lipides': 0,
        'glucides': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Une erreur est survenue : $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final macros = _parametres != null ? {
      'Calories': {
        'actuel': _macrosJour?['calories'] ?? 0.0,
        'objectif': _parametres!.caloriesQuotidiennes,
        'unite': 'kcal'
      },
      'Protéines': {
        'actuel': _macrosJour?['proteines'] ?? 0.0,
        'objectif': _parametres!.objectifProteinesGrammes,
        'unite': 'g'
      },
      'Lipides': {
        'actuel': _macrosJour?['lipides'] ?? 0.0,
        'objectif': _parametres!.objectifLipidesGrammes,
        'unite': 'g'
      },
      'Glucides': {
        'actuel': _macrosJour?['glucides'] ?? 0.0,
        'objectif': _parametres!.objectifGlucidesGrammes,
        'unite': 'g'
      },
    } : null;

    final objectives = _parametres != null ? {
      'calories': _parametres!.caloriesQuotidiennes,
      'proteines': _parametres!.objectifProteinesGrammes,
      'lipides': _parametres!.objectifLipidesGrammes,
      'glucides': _parametres!.objectifGlucidesGrammes,
    } : null;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (macros != null) ...[
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
            if (_nutritionHistory != null && objectives != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Évolution des écarts nutritionnels',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _selectedPeriod,
                    items: _periodOptions.map((option) {
                      return DropdownMenuItem<int>(
                        value: option['value'] as int,
                        child: Text(option['label'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPeriod = value;
                        });
                        _loadData();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    NutritionDeltaChart(
                      nutritionData: _nutritionHistory!,
                      objectives: objectives,
                    ),
                    const NutritionChartLegend(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
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
                          '${_aliments?.length ?? 0}',
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
                          '${_alimentsEnRupture?.length ?? 0}',
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
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return Colors.red;
    if (progress < 0.8) return Colors.orange;
    if (progress <= 1.0) return Colors.green;
    return Colors.red;
  }
} 
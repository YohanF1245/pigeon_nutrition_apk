import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:logging/logging.dart';

class NutritionDeltaChart extends StatelessWidget {
  final List<Map<String, dynamic>> nutritionData;
  final Map<String, double> objectives;
  final Logger _logger = Logger('NutritionDeltaChart');

  NutritionDeltaChart({
    Key? key,
    required this.nutritionData,
    required this.objectives,
  }) : super(key: key) {
    _logger.info('Données reçues : $nutritionData');
    _logger.info('Objectifs reçus : $objectives');
  }

  List<FlSpot> _generateSpots(String nutrimentKey) {
    final spots = <FlSpot>[];
    for (var i = 0; i < nutritionData.length; i++) {
      final data = nutritionData[i];
      final valeur = (data[nutrimentKey] as num?)?.toDouble() ?? 0.0;
      final objectif = objectives[nutrimentKey] ?? 0.0;
      
      // Si toutes les valeurs nutritionnelles sont à 0, on considère qu'il n'y a pas de données
      final hasData = data['calories'] != 0.0 || 
                     data['proteines'] != 0.0 || 
                     data['lipides'] != 0.0 || 
                     data['glucides'] != 0.0;
      
      // Si pas de données, on met le delta à 0 au lieu de -objectif
      final delta = hasData ? (valeur - objectif) : 0.0;
      spots.add(FlSpot(i.toDouble(), delta));
    }
    _logger.info('Spots générés pour $nutrimentKey : $spots');
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (nutritionData.isEmpty) {
      return const Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Calculer les valeurs min et max pour l'axe Y
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (var data in nutritionData) {
      // Vérifier si le jour a des données
      final hasData = data['calories'] != 0.0 || 
                     data['proteines'] != 0.0 || 
                     data['lipides'] != 0.0 || 
                     data['glucides'] != 0.0;
      
      if (hasData) {
        for (var nutriment in ['calories', 'proteines', 'lipides', 'glucides']) {
          final valeur = (data[nutriment] as num?)?.toDouble() ?? 0.0;
          final objectif = objectives[nutriment] ?? 0.0;
          final delta = valeur - objectif;
          minY = min(minY, delta);
          maxY = max(maxY, delta);
        }
      }
    }
    
    // Si aucune donnée n'a été trouvée, définir des valeurs par défaut
    if (minY == double.infinity || maxY == double.negativeInfinity) {
      minY = -100;
      maxY = 100;
    }
    
    // Ajouter une marge de 10%
    final range = (maxY - minY).abs();
    minY -= range * 0.1;
    maxY += range * 0.1;

    // Calculer un intervalle approprié pour l'axe Y
    double interval = range / 5; // On veut environ 5 graduations
    // Arrondir l'intervalle à un nombre "propre"
    if (interval > 0) {
      final magnitude = pow(10, (log(interval) / ln10).floor()).toDouble();
      interval = (interval / magnitude).ceil() * magnitude;
    } else {
      interval = 100; // Valeur par défaut si la plage est nulle
    }

    _logger.info('Plage Y calculée : $minY à $maxY, intervalle : $interval');

    // Calculer la largeur minimale nécessaire pour le graphique
    final minWidth = max(
      MediaQuery.of(context).size.width,
      nutritionData.length * 60.0 + 40.0, // 60 pixels par point + 40 pixels de marge
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 40.0, 8.0), // Ajout d'une marge à droite
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    if (value == 0) {
                      return FlLine(
                        color: Colors.grey,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      );
                    }
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < nutritionData.length) {
                          final date = DateTime.parse(nutritionData[value.toInt()]['date']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Formater le nombre pour qu'il soit plus lisible
                        String text;
                        if (value.abs() >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return Text(
                          text,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                lineBarsData: [
                  // Ligne pour les calories
                  LineChartBarData(
                    spots: _generateSpots('calories'),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  // Ligne pour les protéines
                  LineChartBarData(
                    spots: _generateSpots('proteines'),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  // Ligne pour les lipides
                  LineChartBarData(
                    spots: _generateSpots('lipides'),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  // Ligne pour les glucides
                  LineChartBarData(
                    spots: _generateSpots('glucides'),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
                minY: minY,
                maxY: maxY,
                clipData: FlClipData.all(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Légende du graphique
class NutritionChartLegend extends StatelessWidget {
  const NutritionChartLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          LegendItem(color: Colors.blue, label: 'Calories'),
          LegendItem(color: Colors.red, label: 'Protéines'),
          LegendItem(color: Colors.orange, label: 'Lipides'),
          LegendItem(color: Colors.green, label: 'Glucides'),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({
    Key? key,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 
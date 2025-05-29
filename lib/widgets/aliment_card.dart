import 'package:flutter/material.dart';
import '../models/aliment.dart';
import '../theme/app_theme.dart';
import '../widgets/aliment_dialog.dart';
import '../widgets/ajustement_stock_dialog.dart';
import '../services/aliment_service.dart';
import 'package:logging/logging.dart';

class AlimentCard extends StatelessWidget {
  final Aliment aliment;
  final VoidCallback onModified;
  final VoidCallback onDelete;
  final _alimentService = AlimentService();
  final _logger = Logger('AlimentCard');

  AlimentCard({
    super.key,
    required this.aliment,
    required this.onModified,
    required this.onDelete,
  });

  Future<void> _modifierAliment(BuildContext context) async {
    final result = await AlimentDialog.show(context, aliment: aliment);
    if (result != null) {
      await _alimentService.updateAliment(result);
      onModified();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aliment.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            aliment.stockBas ? Icons.warning : Icons.inventory,
                            color: aliment.stockBas ? Colors.orange : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            aliment.getStockDisplay(),
                            style: TextStyle(
                              color: aliment.stockBas ? Colors.orange : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (aliment.seuilAlerte != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(min: ${aliment.seuilAlerte!.toStringAsFixed(0)} ${aliment.unitePortionLabel ?? aliment.unite.symbole})',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (aliment.gestionStock)
                      IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Icons.inventory),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sync,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          try {
                            final result = await showDialog<double>(
                              context: context,
                              builder: (context) => AjustementStockDialog(aliment: aliment),
                            );
                            if (result != null) {
                              await _alimentService.ajusterStock(aliment.id, result);
                              onModified();
                            }
                          } catch (e) {
                            _logger.severe('Erreur lors de l\'ajustement du stock: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors de l\'ajustement du stock: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        tooltip: 'Ajuster le stock',
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _modifierAliment(context),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                      color: Colors.red,
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutritionBox(
                  label: 'Calories',
                  value: aliment.calories,
                  unit: 'kcal',
                  color: Colors.red[100]!,
                  textColor: Colors.red[900]!,
                ),
                _NutritionBox(
                  label: 'Protéines',
                  value: aliment.proteines,
                  unit: 'g',
                  color: Colors.blue[100]!,
                  textColor: Colors.blue[900]!,
                ),
                _NutritionBox(
                  label: 'Lipides',
                  value: aliment.lipides,
                  unit: 'g',
                  color: Colors.yellow[100]!,
                  textColor: Colors.yellow[900]!,
                ),
                _NutritionBox(
                  label: 'Glucides',
                  value: aliment.glucides,
                  unit: 'g',
                  color: Colors.green[100]!,
                  textColor: Colors.green[900]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionBox extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final Color textColor;

  const _NutritionBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 
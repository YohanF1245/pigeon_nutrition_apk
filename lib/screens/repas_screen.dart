import 'package:flutter/material.dart';
import '../models/repas.dart';
import '../models/aliment.dart';
import '../services/storage_service.dart';
import '../services/aliment_service.dart';
import 'package:intl/intl.dart';
import 'ajouter_repas_screen.dart';

class RepasScreen extends StatefulWidget {
  const RepasScreen({super.key});

  @override
  State<RepasScreen> createState() => _RepasScreenState();
}

class _RepasScreenState extends State<RepasScreen> {
  final StorageService _storageService = StorageService();
  final AlimentService _alimentService = AlimentService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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

  Future<void> _supprimerRepas(String id) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer ce repas ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _storageService.deleteRepas(id);
      setState(() {});
    }
  }

  Future<void> _afficherDetailsRepas(Repas repas) async {
    final aliments = await _alimentService.getAllAliments();
    final nutriments = await repas.calculerNutriments(aliments);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                          repas.nom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormat.format(repas.dateHeure),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Implémenter l'édition
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                        child: const Text('Éditer'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Valider'),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // En-tête
                      Container(
                        color: Colors.grey[200],
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Qté',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Cal',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Prot',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Lip',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Gluc',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Contenu
                      ...repas.aliments.expand((repasAliment) {
                        final aliment = aliments.firstWhere(
                          (a) => a.id == repasAliment.alimentId,
                          orElse: () => throw Exception('Aliment non trouvé'),
                        );
                        final alimentNutriments = aliment.calculerNutriments(repasAliment.quantite);
                        
                        String quantiteAffichee;
                        if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null && aliment.poidsUnitaire! > 0) {
                          final portions = repasAliment.quantite / aliment.poidsUnitaire!;
                          quantiteAffichee = '${portions.toStringAsFixed(1)} ${aliment.unitePortionLabel}${portions > 1 ? 's' : ''} (${repasAliment.quantite.toStringAsFixed(0)}g)';
                        } else {
                          quantiteAffichee = '${repasAliment.quantite.toStringAsFixed(0)}g';
                        }

                        return [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                            child: Text(
                              aliment.nom,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  child: Text(
                                    quantiteAffichee,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  child: Text(
                                    alimentNutriments['calories']!.toStringAsFixed(0),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  child: Text(
                                    alimentNutriments['proteines']!.toStringAsFixed(0),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  child: Text(
                                    alimentNutriments['lipides']!.toStringAsFixed(0),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  child: Text(
                                    alimentNutriments['glucides']!.toStringAsFixed(0),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ];
                      }).toList(),
                      // Total
                      Container(
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Total',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  nutriments['calories']!.toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  nutriments['proteines']!.toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  nutriments['lipides']!.toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  nutriments['glucides']!.toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildNutrimentText(String label, double valeur, Color couleur) {
    return Text(
      '$label: ${valeur.toStringAsFixed(0)}',
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<Map<String, double>> _calculerNutrimentsRepas(Repas repas) async {
    final aliments = await _alimentService.getAllAliments();
    return repas.calculerNutriments(aliments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Repas>>(
        future: _storageService.getRepas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ${snapshot.error}'),
            );
          }

          final repas = snapshot.data ?? [];

          if (repas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_meals,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun repas enregistré',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _ajouterRepas,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un repas'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: repas.length,
            itemBuilder: (context, index) {
              final repasItem = repas[index];
              return FutureBuilder<Map<String, double>>(
                future: _calculerNutrimentsRepas(repasItem),
                builder: (context, nutrimentSnapshot) {
                  if (!nutrimentSnapshot.hasData) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final nutriments = nutrimentSnapshot.data ?? {
                    'calories': 0,
                    'proteines': 0,
                    'lipides': 0,
                    'glucides': 0,
                  };

                  return GestureDetector(
                    onTap: () => _afficherDetailsRepas(repasItem),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                repasItem.nom,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildNutrimentText(
                                  'Cal',
                                  nutriments['calories'] ?? 0,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                _buildNutrimentText(
                                  'Prot',
                                  nutriments['proteines'] ?? 0,
                                  Colors.red,
                                ),
                                const SizedBox(width: 8),
                                _buildNutrimentText(
                                  'Lip',
                                  nutriments['lipides'] ?? 0,
                                  Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                _buildNutrimentText(
                                  'Gluc',
                                  nutriments['glucides'] ?? 0,
                                  Colors.green,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _supprimerRepas(repasItem.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterRepas,
        child: const Icon(Icons.add),
      ),
    );
  }
} 
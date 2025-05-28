import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/aliment.dart';
import '../models/repas.dart';
import '../services/aliment_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../models/unite_base.dart';

class AjouterRepasScreen extends StatefulWidget {
  const AjouterRepasScreen({super.key});

  @override
  State<AjouterRepasScreen> createState() => _AjouterRepasScreenState();
}

class _AjouterRepasScreenState extends State<AjouterRepasScreen> {
  final AlimentService _alimentService = AlimentService();
  final StorageService _storageService = StorageService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  DateTime _dateHeure = DateTime.now();
  final Map<String, double> _alimentsSelectionnes = {};
  List<Aliment> _aliments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerAliments();
    _titreController.text = 'Repas du ${_dateFormat.format(_dateHeure)}';
  }

  @override
  void dispose() {
    _titreController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }

  Future<void> _chargerAliments() async {
    setState(() => _isLoading = true);
    try {
      _aliments = await _alimentService.getAllAliments();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectionnerDateHeure() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateHeure,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateHeure),
      );

      if (time != null) {
        setState(() {
          _dateHeure = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          // Mettre à jour le titre par défaut
          if (_titreController.text.startsWith('Repas du ')) {
            _titreController.text = 'Repas du ${_dateFormat.format(_dateHeure)}';
          }
        });
      }
    }
  }

  void _ajouterAliment(Aliment aliment) {
    final bool utiliserPortion = aliment.unitePortionLabel != null && aliment.poidsUnitaire != null;
    
    if (!mounted) return;

    _quantiteController.clear();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(aliment.nom),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (utiliserPortion) ...[
                Text('Nombre de ${aliment.unitePortionLabel}s :'),
                TextField(
                  controller: _quantiteController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Ex: 1',
                    suffix: Text(aliment.unitePortionLabel!),
                  ),
                ),
              ] else ...[
                const Text('Quantité (en grammes) :'),
                TextField(
                  controller: _quantiteController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 100',
                    suffix: Text('g'),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final quantite = double.tryParse(_quantiteController.text);
                if (quantite != null && quantite > 0) {
                  if (mounted) {
                    setState(() {
                      if (utiliserPortion) {
                        _alimentsSelectionnes[aliment.id] = quantite * aliment.poidsUnitaire!;
                      } else {
                        _alimentsSelectionnes[aliment.id] = quantite;
                      }
                    });
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  void _retirerAliment(String alimentId) {
    setState(() {
      _alimentsSelectionnes.remove(alimentId);
    });
  }

  Future<void> _sauvegarderRepas() async {
    if (_alimentsSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un aliment'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repas = Repas(
        nom: _titreController.text,
        dateHeure: _dateHeure,
        aliments: _alimentsSelectionnes.entries
            .map((e) => RepasAliment(
                  alimentId: e.key,
                  quantite: e.value,
                ))
            .toList(),
      );

      await _storageService.saveRepas(repas);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau repas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _sauvegarderRepas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Champ de titre
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Titre du repas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          TextField(
                            controller: _titreController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Entrez un titre',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sélecteur de date et heure
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_dateFormat.format(_dateHeure)),
                      onTap: _selectionnerDateHeure,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liste des aliments sélectionnés
                  if (_alimentsSelectionnes.isNotEmpty) ...[
                    const Text(
                      'Aliments sélectionnés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: _alimentsSelectionnes.entries.map((entry) {
                          final aliment = _aliments.firstWhere(
                            (a) => a.id == entry.key,
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
                            final portions = entry.value / aliment.poidsUnitaire!;
                            quantiteAffichee = '${portions.toStringAsFixed(1)} ${aliment.unitePortionLabel}${portions > 1 ? 's' : ''} (${entry.value.toStringAsFixed(1)}g)';
                          } else {
                            quantiteAffichee = '${entry.value.toStringAsFixed(1)}g';
                          }

                          return ListTile(
                            title: Text(aliment.nom),
                            subtitle: Text(quantiteAffichee),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _retirerAliment(entry.key),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Liste des aliments disponibles
                  const Text(
                    'Ajouter des aliments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _aliments.map((aliment) {
                        final estSelectionne = _alimentsSelectionnes.containsKey(aliment.id);
                        return ListTile(
                          title: Text(aliment.nom),
                          subtitle: Text(
                            'Stock : ${aliment.getStockDisplay()}',
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              estSelectionne ? Icons.edit : Icons.add,
                              color: estSelectionne ? Colors.orange : null,
                            ),
                            onPressed: () => _ajouterAliment(aliment),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 
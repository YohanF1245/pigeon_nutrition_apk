import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/aliment.dart';
import '../models/repas.dart';
import '../models/jour_repas.dart';
import '../services/aliment_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../models/unite_base.dart';

class AjouterRepasScreen extends StatefulWidget {
  final Repas? repasAModifier;
  final DateTime? dateHeure;
  
  const AjouterRepasScreen({
    super.key,
    this.repasAModifier,
    this.dateHeure,
  });

  @override
  State<AjouterRepasScreen> createState() => _AjouterRepasScreenState();
}

class _AjouterRepasScreenState extends State<AjouterRepasScreen> {
  final AlimentService _alimentService = AlimentService();
  final StorageService _storageService = StorageService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  late DateTime _dateHeure;
  late final Map<String, double> _alimentsSelectionnes;
  List<Aliment> _aliments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateHeure = widget.dateHeure ?? DateTime.now();
    _alimentsSelectionnes = widget.repasAModifier?.aliments.fold<Map<String, double>>(
      {},
      (map, repasAliment) {
        map[repasAliment.alimentId] = repasAliment.quantite;
        return map;
      },
    ) ?? {};
    _titreController.text = widget.repasAModifier?.nom ?? 'Repas du ${_dateFormat.format(_dateHeure)}';
    _chargerAliments();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quantité de ${aliment.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (utiliserPortion)
              Text('1 ${aliment.unitePortionLabel} = ${aliment.poidsUnitaire}g'),
            TextField(
              controller: _quantiteController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: utiliserPortion ? 'Nombre de portions' : 'Quantité en grammes',
                suffixText: utiliserPortion ? aliment.unitePortionLabel : 'g',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final quantiteTexte = _quantiteController.text;
              if (quantiteTexte.isNotEmpty) {
                final quantite = double.parse(quantiteTexte);
                setState(() {
                  _alimentsSelectionnes[aliment.id] = utiliserPortion
                      ? quantite * (aliment.poidsUnitaire ?? 0)
                      : quantite;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _sauvegarder() async {
    if (_alimentsSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un aliment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repas = widget.repasAModifier?.copyWith(
        nom: _titreController.text,
        aliments: _alimentsSelectionnes.entries
            .map((e) => RepasAliment(
                  alimentId: e.key,
                  quantite: e.value,
                ))
            .toList(),
      ) ?? Repas(
        nom: _titreController.text,
        aliments: _alimentsSelectionnes.entries
            .map((e) => RepasAliment(
                  alimentId: e.key,
                  quantite: e.value,
                ))
            .toList(),
      );

      await _storageService.saveRepas(repas);

      // Si une date est spécifiée, créer un JourRepas
      if (widget.dateHeure != null) {
        final jourRepas = JourRepas(
          date: DateTime(
            _dateHeure.year,
            _dateHeure.month,
            _dateHeure.day,
          ),
          repasId: repas.id,
          heure: _dateHeure.hour,
          minute: _dateHeure.minute,
        );
        await _storageService.saveJourRepas(jourRepas);
      }

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
        title: Text(widget.repasAModifier != null ? 'Modifier le repas' : 'Ajouter un repas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _sauvegarder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titreController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du repas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sélecteur de date et heure
                  if (widget.dateHeure != null)
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
                    ..._alimentsSelectionnes.entries.map((entry) {
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

                      return Card(
                        child: ListTile(
                          title: Text(aliment.nom),
                          subtitle: Text(quantiteAffichee),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _alimentsSelectionnes.remove(entry.key);
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    'Ajouter des aliments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_aliments.map((aliment) => Card(
                    child: ListTile(
                      title: Text(aliment.nom),
                      subtitle: Text('${aliment.calories.toStringAsFixed(0)} kcal / 100g'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _ajouterAliment(aliment),
                      ),
                    ),
                  ))),
                ],
              ),
            ),
    );
  }
} 
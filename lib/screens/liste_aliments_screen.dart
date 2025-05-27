import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/aliment.dart';
import '../services/storage_service.dart';

class ListeAlimentsScreen extends StatefulWidget {
  const ListeAlimentsScreen({super.key});

  @override
  State<ListeAlimentsScreen> createState() => _ListeAlimentsScreenState();
}

class _ListeAlimentsScreenState extends State<ListeAlimentsScreen> {
  final StorageService _storageService = StorageService();
  List<Aliment> _aliments = [];
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String _nom = '';
  double _proteines = 0;
  double _lipides = 0;
  double _glucides = 0;
  double _fibres = 0;
  double _quantiteStock = 0;
  String _unite = 'g';
  String? _uniteConversion;
  double? _facteurConversion;
  bool _autoDecrease = false;
  double? _quantiteJournaliere;
  double _seuilAlerte = 0;
  int _quantiteAchat = 1;

  @override
  void initState() {
    super.initState();
    _chargerAliments();
  }

  Future<void> _chargerAliments() async {
    final aliments = await _storageService.getAliments();
    setState(() {
      _aliments = aliments;
    });
  }

  void _ajouterAliment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un aliment'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                  onSaved: (value) => _nom = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Protéines (g/100g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _proteines = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Lipides (g/100g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _lipides = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Glucides (g/100g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _glucides = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Fibres (g/100g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _fibres = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantité en stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _quantiteStock = double.parse(value!),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Unité de base'),
                  value: _unite,
                  items: const [
                    DropdownMenuItem(value: 'g', child: Text('Grammes (g)')),
                    DropdownMenuItem(value: 'kg', child: Text('Kilogrammes (kg)')),
                  ],
                  onChanged: (value) => setState(() => _unite = value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Unité de conversion (optionnel)',
                    hintText: 'Ex: boite, oeuf, tranche',
                  ),
                  onSaved: (value) => _uniteConversion = value?.isNotEmpty == true ? value : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Facteur de conversion (optionnel)',
                    hintText: 'Ex: 100 pour 1 boite = 100g',
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _facteurConversion = value?.isNotEmpty == true ? double.parse(value!) : null,
                ),
                SwitchListTile(
                  title: const Text('Diminution automatique du stock'),
                  value: _autoDecrease,
                  onChanged: (value) => setState(() => _autoDecrease = value),
                ),
                if (_autoDecrease)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Quantité journalière',
                      hintText: 'Ex: 4 pour 4 oeufs par jour',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _autoDecrease
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une valeur';
                            }
                            return null;
                          }
                        : null,
                    onSaved: (value) => _quantiteJournaliere = value?.isNotEmpty == true ? double.parse(value!) : null,
                  ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Seuil d\'alerte',
                    hintText: 'Quantité minimale avant alerte',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _seuilAlerte = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Quantité par achat',
                    hintText: 'Ex: 12 pour une boite de 12 oeufs',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une valeur';
                    }
                    return null;
                  },
                  onSaved: (value) => _quantiteAchat = int.parse(value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final nouvelAliment = Aliment(
                  id: _uuid.v4(),
                  nom: _nom,
                  proteines: _proteines,
                  lipides: _lipides,
                  glucides: _glucides,
                  fibres: _fibres,
                  quantiteStock: _quantiteStock,
                  unite: _unite,
                  uniteConversion: _uniteConversion,
                  facteurConversion: _facteurConversion,
                  autoDecrease: _autoDecrease,
                  quantiteJournaliere: _quantiteJournaliere,
                  seuilAlerte: _seuilAlerte,
                  quantiteAchat: _quantiteAchat,
                );
                await _storageService.addAliment(nouvelAliment);
                await _chargerAliments();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Aliments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterAliment,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _aliments.length,
        itemBuilder: (context, index) {
          final aliment = _aliments[index];
          return Card(
            child: ListTile(
              title: Text(aliment.nom),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock: ${aliment.quantiteStock} ${aliment.unite}'),
                  if (aliment.uniteConversion != null)
                    Text('Conversion: 1 ${aliment.uniteConversion} = ${aliment.facteurConversion}${aliment.unite}'),
                  Text('Protéines: ${aliment.proteines}g/100g'),
                  Text('Lipides: ${aliment.lipides}g/100g'),
                  Text('Glucides: ${aliment.glucides}g/100g'),
                  if (aliment.autoDecrease)
                    Text('Consommation journalière: ${aliment.quantiteJournaliere} ${aliment.uniteConversion ?? aliment.unite}'),
                  Text('Seuil d\'alerte: ${aliment.seuilAlerte} ${aliment.unite}'),
                  Text('Quantité par achat: ${aliment.quantiteAchat} ${aliment.uniteConversion ?? aliment.unite}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Implémenter la modification
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _storageService.deleteAliment(aliment.id);
                      await _chargerAliments();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 
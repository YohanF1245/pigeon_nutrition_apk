import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/parametres_nutritionnels.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/database_management_section.dart';

class ParametresNutritionnelsScreen extends StatefulWidget {
  const ParametresNutritionnelsScreen({super.key});

  @override
  State<ParametresNutritionnelsScreen> createState() => _ParametresNutritionnelsScreenState();
}

class _ParametresNutritionnelsScreenState extends State<ParametresNutritionnelsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  final _uuid = const Uuid();

  // Controllers pour les champs de texte
  late TextEditingController _poidsController;
  late TextEditingController _tailleController;
  late TextEditingController _ageController;

  double _poids = 70;
  double _taille = 170;
  int _age = 30;
  String _sexe = 'homme';
  String _niveauActivite = 'modere';
  String _objectif = 'maintien';
  double _objectifProteines = 30;
  double _objectifLipides = 25;
  double _objectifGlucides = 45;
  double _protsParKg = 1.6; // valeur par défaut pour maintien

  ParametresNutritionnels? _parametres;
  bool _isLoading = true;
  bool _calculAutomatique = true;

  @override
  void initState() {
    super.initState();
    _poidsController = TextEditingController(text: _poids.toString());
    _tailleController = TextEditingController(text: _taille.toString());
    _ageController = TextEditingController(text: _age.toString());
    _protsParKg = _getDefaultProtsParKg(_objectif);
    _chargerParametres();
  }

  double _getDefaultProtsParKg(String objectif) {
    if (objectif == 'perte') return 2.0;
    if (objectif == 'prise') return 1.6;
    return 1.6; // maintien
  }

  @override
  void dispose() {
    _poidsController.dispose();
    _tailleController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _chargerParametres() async {
    final parametres = await _storageService.getParametresNutritionnels();
    if (parametres != null) {
      setState(() {
        _parametres = parametres;
        _poids = parametres.poids;
        _taille = parametres.taille;
        _age = parametres.age;
        _sexe = parametres.sexe;
        _niveauActivite = parametres.niveauActivite;
        _objectif = parametres.objectif;
        _objectifProteines = parametres.objectifProteines;
        _objectifLipides = parametres.objectifLipides;
        _objectifGlucides = parametres.objectifGlucides;
        _poidsController.text = _poids.toString();
        _tailleController.text = _taille.toString();
        _ageController.text = _age.toString();
        // Correction de la valeur du slider si hors bornes
        double min = 1.2, max = 2.4;
        if (_objectif == 'perte') { min = 2.0; max = 2.4; }
        if (_objectif == 'prise') { min = 1.6; max = 2.0; }
        double val = 0;
        final poidsDouble = double.tryParse(_poids.toString()) ?? 1.0;
        final protG = double.tryParse(parametres.objectifProteinesGrammes.toString()) ?? 0.0;
        if (protG > 0) {
          val = protG / poidsDouble;
        } else {
          val = _getDefaultProtsParKg(_objectif);
        }
        if (val < min || val > max) val = min;
        _protsParKg = val;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sauvegarderParametres() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final parametres = ParametresNutritionnels(
        id: _parametres?.id ?? _uuid.v4(),
        poids: _poids,
        taille: _taille,
        age: _age,
        sexe: _sexe,
        niveauActivite: _niveauActivite,
        objectif: _objectif,
        objectifProteines: _objectifProteines,
        objectifLipides: _objectifLipides,
        objectifGlucides: _objectifGlucides,
      );
      
      // Recalculer les besoins avec le mode approprié
      parametres.calculerBesoins(calculAutomatique: _calculAutomatique);
      
      await _storageService.saveParametresNutritionnels(parametres);
      setState(() {
        _parametres = parametres;
        // Mettre à jour les valeurs affichées
        _objectifProteines = parametres.objectifProteines;
        _objectifLipides = parametres.objectifLipides;
        _objectifGlucides = parametres.objectifGlucides;
        _protsParKg = parametres.proteinesParKg;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  void _calculerMacrosAutomatiques() {
    if (!_calculAutomatique) return;
    
    final parametres = ParametresNutritionnels(
      id: _parametres?.id ?? _uuid.v4(),
      poids: _poids,
      taille: _taille,
      age: _age,
      sexe: _sexe,
      niveauActivite: _niveauActivite,
      objectif: _objectif,
    );
    
    parametres.calculerBesoins(calculAutomatique: true);
    
    setState(() {
      _objectifProteines = parametres.objectifProteines;
      _objectifLipides = parametres.objectifLipides;
      _objectifGlucides = parametres.objectifGlucides;
      _protsParKg = parametres.proteinesParKg;
    });
  }

  void _afficherGuideNutrition() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guide des Macronutriments'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideSection(
                'Qu\'est-ce que les macronutriments ?',
                'Les macronutriments sont les trois principales catégories de nutriments dont votre corps a besoin en grande quantité : protéines, lipides et glucides.',
              ),
              const Divider(),
              _buildGuideSection(
                'Protéines',
                '• Essentielles pour la croissance et la réparation musculaire\n'
                '• Sources : viandes, œufs, légumineuses\n'
                '• 1g = 4 calories',
              ),
              const Divider(),
              _buildGuideSection(
                'Lipides',
                '• Importants pour l\'absorption des vitamines et la production d\'hormones\n'
                '• Sources : huiles, noix, avocats\n'
                '• 1g = 9 calories',
              ),
              const Divider(),
              _buildGuideSection(
                'Glucides',
                '• Principale source d\'énergie du corps\n'
                '• Sources : céréales, fruits, légumes\n'
                '• 1g = 4 calories',
              ),
              const Divider(),
              _buildGuideSection(
                'Recommandations par objectif',
                '• Perte de poids : ↑ protéines, ↓ glucides\n'
                '• Maintien : répartition équilibrée\n'
                '• Prise de masse : ↑ protéines et glucides',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(content),
      ],
    );
  }

  double get _caloriesObjectif {
    if (_parametres == null) return 0;
    return _parametres!.caloriesQuotidiennes;
  }

  double get _protPourcent {
    if (_parametres == null) return 0;
    return _parametres!.objectifProteines;
  }

  double get _glucidesPourcent {
    if (_parametres == null) return 0;
    return _parametres!.objectifGlucides;
  }

  Widget _buildSliderLipides() {
    final maxLipides = (100 - _protPourcent).clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lipides : ${_objectifLipides.round()}%'),
        const SizedBox(height: 4),
        Text(
          'Important pour les hormones et l\'absorption des vitamines',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Slider(
          value: _objectifLipides,
          min: 0,
          max: maxLipides,
          divisions: maxLipides > 0 ? maxLipides.round() : 1,
          onChanged: _calculAutomatique ? null : (value) {
            setState(() {
              _objectifLipides = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSliderGlucides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Glucides : ${_glucidesPourcent.round()}%'),
        const SizedBox(height: 4),
        Text(
          'Principale source d\'énergie',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Slider(
          value: _glucidesPourcent,
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _sauvegarderParametres,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('Données Physiques'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _poidsController,
                            decoration: const InputDecoration(
                              labelText: 'Poids (kg)',
                              suffixText: 'kg',
                            ),
                            keyboardType: TextInputType.number,
                            onTap: () {
                              _poidsController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _poidsController.text.length,
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre poids';
                              }
                              final poids = double.tryParse(value);
                              if (poids == null || poids <= 0) {
                                return 'Veuillez entrer un poids valide';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final poids = double.tryParse(value);
                                if (poids != null) {
                                  setState(() => _poids = poids);
                                }
                              }
                            },
                            onSaved: (value) => _poids = double.parse(value!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tailleController,
                            decoration: const InputDecoration(
                              labelText: 'Taille (cm)',
                              suffixText: 'cm',
                            ),
                            keyboardType: TextInputType.number,
                            onTap: () {
                              _tailleController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _tailleController.text.length,
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre taille';
                              }
                              final taille = double.tryParse(value);
                              if (taille == null || taille <= 0) {
                                return 'Veuillez entrer une taille valide';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final taille = double.tryParse(value);
                                if (taille != null) {
                                  setState(() => _taille = taille);
                                }
                              }
                            },
                            onSaved: (value) => _taille = double.parse(value!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Âge',
                              suffixText: 'ans',
                            ),
                            keyboardType: TextInputType.number,
                            onTap: () {
                              _ageController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _ageController.text.length,
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre âge';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age <= 0) {
                                return 'Veuillez entrer un âge valide';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final age = int.tryParse(value);
                                if (age != null) {
                                  setState(() => _age = age);
                                }
                              }
                            },
                            onSaved: (value) => _age = int.parse(value!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _sexe,
                            decoration: const InputDecoration(
                              labelText: 'Sexe',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'homme', child: Text('Homme')),
                              DropdownMenuItem(value: 'femme', child: Text('Femme')),
                            ],
                            onChanged: (value) => setState(() => _sexe = value!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _niveauActivite,
                            decoration: const InputDecoration(
                              labelText: 'Niveau d\'activité',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'sedentaire',
                                child: Text('Sédentaire (peu ou pas d\'exercice)'),
                              ),
                              DropdownMenuItem(
                                value: 'leger',
                                child: Text('Léger (exercice 1-3 fois/semaine)'),
                              ),
                              DropdownMenuItem(
                                value: 'modere',
                                child: Text('Modéré (exercice 3-5 fois/semaine)'),
                              ),
                              DropdownMenuItem(
                                value: 'intense',
                                child: Text('Intense (exercice 6-7 fois/semaine)'),
                              ),
                              DropdownMenuItem(
                                value: 'tres_intense',
                                child: Text('Très intense (exercice quotidien)'),
                              ),
                            ],
                            onChanged: (value) => setState(() => _niveauActivite = value!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _objectif,
                            decoration: const InputDecoration(
                              labelText: 'Objectif',
                              helperText: 'Votre objectif déterminera la répartition recommandée des macronutriments',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'perte',
                                child: Text('Perte de poids'),
                              ),
                              DropdownMenuItem(
                                value: 'maintien',
                                child: Text('Maintien du poids'),
                              ),
                              DropdownMenuItem(
                                value: 'prise',
                                child: Text('Prise de masse'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _objectif = value!;
                                _calculerMacrosAutomatiques();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Objectifs Macronutriments'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Calcul automatique'),
                            subtitle: const Text(
                              'Laissez l\'application optimiser la répartition des macronutriments selon votre objectif',
                            ),
                            value: _calculAutomatique,
                            onChanged: (value) {
                              setState(() {
                                _calculAutomatique = value;
                                if (value) {
                                  _calculerMacrosAutomatiques();
                                }
                              });
                            },
                          ),
                          const Divider(),
                          _buildSliderProteines(),
                          _buildSliderLipides(),
                          _buildSliderGlucides(),
                        ],
                      ),
                    ),
                  ),
                  if (_parametres != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Valeurs Calculées'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildCalculatedValue(
                              'TMB',
                              '${_parametres!.tmb.round()} kcal',
                              'Taux Métabolique de Base',
                            ),
                            const Divider(),
                            _buildCalculatedValue(
                              'Calories Quotidiennes',
                              '${_parametres!.caloriesQuotidiennes.round()} kcal',
                              'Besoin énergétique total',
                            ),
                            const Divider(),
                            _buildCalculatedValue(
                              'Protéines',
                              '${_parametres!.objectifProteinesGrammes.round()}g',
                              '${_parametres!.objectifProteines}% des calories',
                            ),
                            const Divider(),
                            _buildCalculatedValue(
                              'Lipides',
                              '${_parametres!.objectifLipidesGrammes.round()}g',
                              '${_parametres!.objectifLipides}% des calories',
                            ),
                            const Divider(),
                            _buildCalculatedValue(
                              'Glucides',
                              '${_parametres!.objectifGlucidesGrammes.round()}g',
                              '${_parametres!.objectifGlucides}% des calories',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            DatabaseManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkBlue,
        ),
      ),
    );
  }

  Widget _buildSliderProteines() {
    // Fourchette selon l'objectif
    double min = 1.2;
    double max = 2.4;
    if (_objectif == 'perte') {
      min = 2.0;
      max = 2.4;
    } else if (_objectif == 'prise') {
      min = 1.6;
      max = 2.0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Protéines : ${_protsParKg.toStringAsFixed(2)} g/kg'),
        const SizedBox(height: 4),
        Text(
          'Soit ${( _protsParKg * _poids ).round()}g par jour',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Slider(
          value: _protsParKg,
          min: min,
          max: max,
          divisions: ((max - min) * 100).round(),
          onChanged: _calculAutomatique ? null : (value) {
            setState(() {
              _protsParKg = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalculatedValue(String label, String value, String description) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
          ),
        ],
      ),
      subtitle: Text(description),
    );
  }
} 
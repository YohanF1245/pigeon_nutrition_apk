import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/parametres_nutritionnels.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ParametresNutritionnelsScreen extends StatefulWidget {
  const ParametresNutritionnelsScreen({super.key});

  @override
  State<ParametresNutritionnelsScreen> createState() => _ParametresNutritionnelsScreenState();
}

class _ParametresNutritionnelsScreenState extends State<ParametresNutritionnelsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  final _uuid = const Uuid();

  double _poids = 70;
  double _taille = 170;
  int _age = 30;
  String _sexe = 'homme';
  String _niveauActivite = 'modere';
  String _objectif = 'maintien';
  double _objectifProteines = 30;
  double _objectifLipides = 25;
  double _objectifGlucides = 45;

  ParametresNutritionnels? _parametres;
  bool _isLoading = true;
  bool _calculAutomatique = true;

  @override
  void initState() {
    super.initState();
    _chargerParametres();
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
        _objectifProteines = parametres.objectifProteines;
        _objectifLipides = parametres.objectifLipides;
        _objectifGlucides = parametres.objectifGlucides;
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
        objectifProteines: _objectifProteines,
        objectifLipides: _objectifLipides,
        objectifGlucides: _objectifGlucides,
      );

      await _storageService.saveParametresNutritionnels(parametres);
      setState(() {
        _parametres = parametres;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres sauvegardés')),
        );
      }
    }
  }

  void _calculerMacrosAutomatiques() {
    if (!_calculAutomatique) return;

    switch (_objectif) {
      case 'perte':
        _objectifProteines = 35;
        _objectifLipides = 30;
        _objectifGlucides = 35;
        break;
      case 'maintien':
        _objectifProteines = 30;
        _objectifLipides = 25;
        _objectifGlucides = 45;
        break;
      case 'prise':
        _objectifProteines = 30;
        _objectifLipides = 20;
        _objectifGlucides = 50;
        break;
    }
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Données Physiques'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _poids.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      suffixText: 'kg',
                    ),
                    keyboardType: TextInputType.number,
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
                    onSaved: (value) => _poids = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _taille.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Taille (cm)',
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
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
                    onSaved: (value) => _taille = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _age.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Âge',
                      suffixText: 'ans',
                    ),
                    keyboardType: TextInputType.number,
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
                  _buildSlider(
                    label: 'Protéines',
                    value: _objectifProteines,
                    onChanged: _calculAutomatique ? null : (value) {
                      setState(() {
                        _objectifProteines = value;
                        _objectifGlucides = 100 - _objectifProteines - _objectifLipides;
                      });
                    },
                    description: 'Essentielles pour la croissance et la réparation musculaire',
                  ),
                  _buildSlider(
                    label: 'Lipides',
                    value: _objectifLipides,
                    onChanged: _calculAutomatique ? null : (value) {
                      setState(() {
                        _objectifLipides = value;
                        _objectifGlucides = 100 - _objectifProteines - _objectifLipides;
                      });
                    },
                    description: 'Importants pour les hormones et l\'absorption des vitamines',
                  ),
                  _buildSlider(
                    label: 'Glucides',
                    value: _objectifGlucides,
                    enabled: false,
                    description: 'Principale source d\'énergie',
                  ),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sauvegarderParametres,
              child: const Text('Sauvegarder'),
            ),
          ),
        ],
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

  Widget _buildSlider({
    required String label,
    required double value,
    void Function(double)? onChanged,
    bool enabled = true,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}%'),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: onChanged,
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
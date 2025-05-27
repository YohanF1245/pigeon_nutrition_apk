import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/aliment.dart';
import '../models/unite_base.dart';
import '../theme/app_theme.dart';

class AlimentDialog extends StatefulWidget {
  final Aliment? aliment;

  const AlimentDialog({super.key, this.aliment});

  static Future<Aliment?> show(BuildContext context, {Aliment? aliment}) {
    return showDialog<Aliment>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlimentDialog(aliment: aliment),
    );
  }

  @override
  State<AlimentDialog> createState() => _AlimentDialogState();
}

class _AlimentDialogState extends State<AlimentDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final _nomController = TextEditingController();
  final _uniteSecondaireController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _deviseController = TextEditingController();
  final _quantiteStockController = TextEditingController();
  final _seuilAlerteController = TextEditingController();
  final _decrementationJournaliereController = TextEditingController();
  final _quantiteAchatParDefautController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinesController = TextEditingController();
  final _lipidesController = TextEditingController();
  final _glucidesController = TextEditingController();
  final _facteurConversionController = TextEditingController();
  bool _gestionStock = false;
  bool _autoDecrementation = false;
  UniteBase _unite = UniteBase.gramme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.aliment != null) {
      final aliment = widget.aliment!;
      _nomController.text = aliment.nom;
      _unite = aliment.unite;
      _uniteSecondaireController.text = aliment.uniteSecondaire ?? '';
      _prixUnitaireController.text = aliment.prixUnitaire.toString();
      _deviseController.text = aliment.devise;
      _quantiteStockController.text = aliment.quantiteStock.toString();
      _seuilAlerteController.text = aliment.seuilAlerte?.toString() ?? '';
      _decrementationJournaliereController.text = aliment.decrementationJournaliere?.toString() ?? '';
      _quantiteAchatParDefautController.text = aliment.quantiteAchatParDefaut.toString();
      _caloriesController.text = aliment.calories.toString();
      _proteinesController.text = aliment.proteines.toString();
      _lipidesController.text = aliment.lipides.toString();
      _glucidesController.text = aliment.glucides.toString();
      _facteurConversionController.text = aliment.facteurConversion?.toString() ?? '';
      _gestionStock = aliment.gestionStock;
      if (_gestionStock) {
        _autoDecrementation = aliment.decrementationJournaliere != null;
        if (_autoDecrementation) {
          _decrementationJournaliereController.text = aliment.decrementationJournaliere?.toString() ?? '';
        }
      }
    } else {
      _prixUnitaireController.text = '0';
      _deviseController.text = 'EUR';
      _quantiteStockController.text = '0';
      _quantiteAchatParDefautController.text = '1000';
      _caloriesController.text = '0';
      _proteinesController.text = '0';
      _lipidesController.text = '0';
      _glucidesController.text = '0';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _uniteSecondaireController.dispose();
    _prixUnitaireController.dispose();
    _deviseController.dispose();
    _quantiteStockController.dispose();
    _seuilAlerteController.dispose();
    _decrementationJournaliereController.dispose();
    _quantiteAchatParDefautController.dispose();
    _caloriesController.dispose();
    _proteinesController.dispose();
    _lipidesController.dispose();
    _glucidesController.dispose();
    _facteurConversionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAlimentTab(),
                    _buildNutritionTab(),
                    _buildStockTab(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        widget.aliment == null ? 'Ajouter' : 'Modifier',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            widget.aliment == null ? 'Nouvel aliment' : 'Modifier l\'aliment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Aliment'),
              Tab(text: 'Nutrition'),
              Tab(text: 'Stock'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildAlimentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              hintText: 'Ex: Maïs',
            ),
            validator: (value) => value?.isEmpty == true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UniteBase>(
                  value: _unite,
                  decoration: const InputDecoration(
                    labelText: 'Unité *',
                  ),
                  items: UniteBase.values.map((unite) {
                    return DropdownMenuItem(
                      value: unite,
                      child: Text(unite.symbole),
                    );
                  }).toList(),
                  onChanged: (UniteBase? value) {
                    if (value != null) {
                      setState(() {
                        _unite = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _uniteSecondaireController,
                  decoration: const InputDecoration(
                    labelText: 'Unité secondaire',
                    hintText: 'Ex: cuillère',
                  ),
                ),
              ),
            ],
          ),
          if (_uniteSecondaireController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _facteurConversionController,
              decoration: const InputDecoration(
                labelText: 'Facteur de conversion',
                hintText: 'Ex: 1 cuillère = 15g, entrez 15',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) return 'Nombre invalide';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valeurs nutritionnelles pour 100${_unite.symbole}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories (kcal)',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateNumber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _proteinesController,
                  decoration: const InputDecoration(
                    labelText: 'Protéines (g)',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lipidesController,
                  decoration: const InputDecoration(
                    labelText: 'Lipides (g)',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateNumber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _glucidesController,
                  decoration: const InputDecoration(
                    labelText: 'Glucides (g)',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateNumber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Gestion du stock'),
            subtitle: const Text('Activer le suivi du stock'),
            value: _gestionStock,
            onChanged: (value) => setState(() {
              _gestionStock = value;
              if (!_gestionStock) {
                _autoDecrementation = false;
                _decrementationJournaliereController.clear();
              }
            }),
          ),
          if (_gestionStock) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantiteStockController,
              decoration: const InputDecoration(
                labelText: 'Quantité en stock',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _seuilAlerteController,
              decoration: const InputDecoration(
                labelText: 'Seuil d\'alerte',
                hintText: 'Quantité minimale avant alerte',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isNotEmpty ? _validateNumber(value) : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Décrémentation automatique'),
              subtitle: const Text('Déduire automatiquement du stock'),
              value: _autoDecrementation,
              onChanged: (value) => setState(() {
                _autoDecrementation = value;
                if (!_autoDecrementation) {
                  _decrementationJournaliereController.clear();
                }
              }),
            ),
            if (_autoDecrementation) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _decrementationJournaliereController,
                decoration: const InputDecoration(
                  labelText: 'Quantité journalière',
                  hintText: 'Quantité à déduire par jour',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isNotEmpty ? _validateNumber(value) : null,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    if (double.tryParse(value) == null) return 'Nombre invalide';
    if (double.parse(value) < 0) return 'Doit être positif';
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final aliment = Aliment(
        id: widget.aliment?.id ?? const Uuid().v4(),
        nom: _nomController.text,
        unite: _unite,
        uniteSecondaire: _uniteSecondaireController.text.isEmpty ? null : _uniteSecondaireController.text,
        prixUnitaire: double.parse(_prixUnitaireController.text),
        devise: _deviseController.text,
        gestionStock: _gestionStock,
        quantiteStock: double.parse(_quantiteStockController.text),
        seuilAlerte: _seuilAlerteController.text.isEmpty ? null : double.parse(_seuilAlerteController.text),
        decrementationJournaliere: _decrementationJournaliereController.text.isEmpty ? null : double.parse(_decrementationJournaliereController.text),
        quantiteAchatParDefaut: double.parse(_quantiteAchatParDefautController.text),
        calories: double.parse(_caloriesController.text),
        proteines: double.parse(_proteinesController.text),
        lipides: double.parse(_lipidesController.text),
        glucides: double.parse(_glucidesController.text),
        facteurConversion: _facteurConversionController.text.isEmpty ? null : double.parse(_facteurConversionController.text),
      );
      Navigator.pop(context, aliment);
    }
  }
} 
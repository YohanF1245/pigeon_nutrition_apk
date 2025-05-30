import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/aliment.dart';
import '../models/unite_base.dart';
import '../theme/app_theme.dart';
import '../services/open_food_facts_service.dart';

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
  final _poidsUnitaireController = TextEditingController();
  final _unitePortionLabelController = TextEditingController();
  final _nombreUniteParLotController = TextEditingController();
  bool _gestionStock = false;
  bool _autoDecrementation = false;
  bool _gestionPortion = false;
  UniteBase _unite = UniteBase.gramme;
  final _openFoodFactsService = OpenFoodFactsService();
  String? _scanError;
  String? _scannedBarcode;
  String? _scanSuccess;
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.aliment != null) {
      final aliment = widget.aliment!;
      _nomController.text = aliment.nom;
      _unite = aliment.unite;
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
      _poidsUnitaireController.text = aliment.poidsUnitaire?.toString() ?? '';
      _unitePortionLabelController.text = aliment.unitePortionLabel ?? '';
      _nombreUniteParLotController.text = aliment.nombreUniteParLot?.toString() ?? '';
      _gestionStock = aliment.gestionStock;
      _gestionPortion = aliment.poidsUnitaire != null;
      if (_gestionStock) {
        _autoDecrementation = aliment.decrementationJournaliere != null;
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
    _poidsUnitaireController.dispose();
    _unitePortionLabelController.dispose();
    _nombreUniteParLotController.dispose();
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
          DropdownButtonFormField<UniteBase>(
            value: _unite,
            decoration: const InputDecoration(
              labelText: 'Unité de base *',
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          if (_scanError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _scanError == 'Données nutritionnelles non disponibles' 
                    ? Colors.orange[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _scanError == 'Données nutritionnelles non disponibles'
                      ? Colors.orange[200]!
                      : Colors.red[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _scanError == 'Données nutritionnelles non disponibles'
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    color: _scanError == 'Données nutritionnelles non disponibles'
                        ? Colors.orange[700]
                        : Colors.red[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scanError == 'Données nutritionnelles non disponibles' 
                              ? 'Données manquantes'
                              : 'Produit non trouvé',
                          style: TextStyle(
                            color: _scanError == 'Données nutritionnelles non disponibles'
                                ? Colors.orange[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_scannedBarcode != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Code-barres: $_scannedBarcode',
                            style: TextStyle(
                              color: _scanError == 'Données nutritionnelles non disponibles'
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _scanError == 'Données nutritionnelles non disponibles'
                              ? 'Les informations nutritionnelles ne sont pas disponibles dans la base de données. Veuillez les saisir manuellement.'
                              : 'Le produit n\'est pas dans la base de données Open Food Facts.',
                          style: TextStyle(
                            color: _scanError == 'Données nutritionnelles non disponibles'
                                ? Colors.orange[700]
                                : Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: _scanError == 'Données nutritionnelles non disponibles'
                        ? Colors.orange[700]
                        : Colors.red[700],
                    onPressed: () {
                      setState(() {
                        _scanError = null;
                        _scannedBarcode = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_scanSuccess != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Données récupérées',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_scannedBarcode != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Code-barres: $_scannedBarcode',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Les informations nutritionnelles ont été importées avec succès.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.green[700],
                    onPressed: () {
                      setState(() {
                        _scanSuccess = null;
                        _scannedBarcode = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Text(
            'Scanner de code-barres',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scannez le code-barres d\'un produit pour récupérer automatiquement ses informations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.normal,
                  facing: CameraFacing.back,
                ),
                onDetect: (capture) async {
                  final now = DateTime.now();
                  if (_lastScanTime != null && now.difference(_lastScanTime!) < _scanCooldown) {
                    return;
                  }
                  _lastScanTime = now;

                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      final product = await _openFoodFactsService.getProductByBarcode(barcode.rawValue!);
                      if (product != null) {
                        print('Produit trouvé: ${product.toString()}');
                        final nutriments = product['nutriments'] as Map<String, dynamic>?;
                        print('Nutriments: ${nutriments.toString()}');
                        
                        setState(() {
                          _nomController.text = product['product_name'] ?? product['name'] ?? '';
                          
                          final calories = nutriments?['energy-kcal_100g'] ?? 
                                         nutriments?['energy_100g'] ?? 0;
                          final proteines = nutriments?['proteins_100g'] ?? 0;
                          final lipides = nutriments?['fat_100g'] ?? 0;
                          final glucides = nutriments?['carbohydrates_100g'] ?? 0;

                          print('Valeurs extraites:');
                          print('Calories: $calories');
                          print('Protéines: $proteines');
                          print('Lipides: $lipides');
                          print('Glucides: $glucides');

                          final allValuesZero = calories == 0 && proteines == 0 && lipides == 0 && glucides == 0;

                          if (allValuesZero) {
                            _scanError = 'Données nutritionnelles non disponibles';
                            _scanSuccess = null;
                            _scannedBarcode = barcode.rawValue;
                          } else {
                            _caloriesController.text = calories.toString();
                            _proteinesController.text = proteines.toString();
                            _lipidesController.text = lipides.toString();
                            _glucidesController.text = glucides.toString();
                            _scanError = null;
                            _scanSuccess = 'Données récupérées';
                            _scannedBarcode = barcode.rawValue;
                          }
                        });
                      } else {
                        setState(() {
                          _scanError = 'Produit non trouvé';
                          _scanSuccess = null;
                          _scannedBarcode = barcode.rawValue;
                        });
                      }
                      break;
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Gestion par portion'),
            subtitle: const Text('Définir une unité de portion (tranche, unité...)'),
            value: _gestionPortion,
            onChanged: (value) => setState(() {
              _gestionPortion = value;
              if (!_gestionPortion) {
                _poidsUnitaireController.clear();
                _unitePortionLabelController.clear();
                _nombreUniteParLotController.clear();
              }
              _updateQuantiteAchatParDefaut();
            }),
          ),
          if (_gestionPortion) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _poidsUnitaireController,
              decoration: const InputDecoration(
                labelText: 'Poids par unité (en grammes)',
                hintText: 'Ex: 30 pour une tranche de 30g',
              ),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onTap: () => _poidsUnitaireController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _poidsUnitaireController.text.length,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitePortionLabelController,
              decoration: const InputDecoration(
                labelText: 'Label de l\'unité',
                hintText: 'Ex: tranche, unité, boîte',
              ),
              validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreUniteParLotController,
              decoration: const InputDecoration(
                labelText: 'Nombre d\'unités par lot',
                hintText: 'Ex: 6 tranches par paquet',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isNotEmpty ? _validateNumber(value) : null,
              onTap: () => _nombreUniteParLotController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _nombreUniteParLotController.text.length,
              ),
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
          Text(
            'Valeurs manuelles',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[700],
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
                  onTap: () => _caloriesController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _caloriesController.text.length,
                  ),
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
                  onTap: () => _proteinesController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _proteinesController.text.length,
                  ),
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
                  onTap: () => _lipidesController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _lipidesController.text.length,
                  ),
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
                  onTap: () => _glucidesController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _glucidesController.text.length,
                  ),
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
              decoration: InputDecoration(
                labelText: _gestionPortion 
                  ? 'Quantité en stock (en ${_unitePortionLabelController.text})'
                  : 'Quantité en stock (en ${_unite.symbole})',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onTap: () => _quantiteStockController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _quantiteStockController.text.length,
              ),
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
              onTap: () => _seuilAlerteController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _seuilAlerteController.text.length,
              ),
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
                onTap: () => _decrementationJournaliereController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _decrementationJournaliereController.text.length,
                ),
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
        poidsUnitaire: _gestionPortion && _poidsUnitaireController.text.isNotEmpty ? double.parse(_poidsUnitaireController.text) : null,
        unitePortionLabel: _gestionPortion ? _unitePortionLabelController.text : null,
        nombreUniteParLot: _gestionPortion && _nombreUniteParLotController.text.isNotEmpty ? int.parse(_nombreUniteParLotController.text) : null,
      );
      Navigator.pop(context, aliment);
    }
  }

  void _updateQuantiteAchatParDefaut() {
    if (_gestionPortion) {
      _quantiteAchatParDefautController.text = '1';
    } else {
      _quantiteAchatParDefautController.text = '1000';
    }
  }
} 
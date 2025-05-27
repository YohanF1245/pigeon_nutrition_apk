import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/aliment.dart';
import '../services/aliment_service.dart';
import '../theme/app_theme.dart';

class AlimentsScreen extends StatefulWidget {
  const AlimentsScreen({super.key});

  @override
  State<AlimentsScreen> createState() => _AlimentsScreenState();
}

class _AlimentsScreenState extends State<AlimentsScreen> {
  final AlimentService _alimentService = AlimentService();
  List<Aliment> _aliments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerAliments();
  }

  Future<void> _chargerAliments() async {
    setState(() => _isLoading = true);
    try {
      final aliments = await _alimentService.getAllAliments();
      setState(() {
        _aliments = aliments;
        _isLoading = false;
      });
    } catch (e) {
      // Ne pas afficher d'erreur si la liste est vide
      setState(() {
        _aliments = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _ajouterOuModifierAliment(Aliment? aliment) async {
    final isModification = aliment != null;
    try {
      final result = await showDialog<Aliment>(
        context: context,
        builder: (context) => AlimentDialog(aliment: aliment),
      );

      if (result != null) {
        print('Données de l\'aliment à sauvegarder: ${result.toMap()}');
        try {
          if (isModification) {
            await _alimentService.updateAliment(result);
            print('Modification réussie');
          } else {
            await _alimentService.insertAliment(result);
            print('Ajout réussi');
          }
          await _chargerAliments();
        } catch (e, stackTrace) {
          print('Erreur lors de la sauvegarde: $e');
          print('Stack trace: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isModification
                      ? 'Erreur lors de la modification: $e'
                      : 'Erreur lors de l\'ajout: $e',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      print('Erreur lors de l\'affichage du dialogue: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _supprimerAliment(String id) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet aliment ?'),
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
      try {
        await _alimentService.deleteAliment(id);
        await _chargerAliments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }

  Future<void> _ajusterStock(Aliment aliment) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AjustementStockDialog(aliment: aliment),
    );

    if (result != null) {
      try {
        await _alimentService.ajusterStock(aliment.id, result);
        await _chargerAliments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ajustement du stock')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_aliments.isEmpty) {
      return Center(
        child: Text(
          'Aucun aliment enregistré',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: _aliments.length,
      itemBuilder: (context, index) {
        final aliment = _aliments[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 4.0,
          ),
          child: ListTile(
            title: Text(aliment.nom),
            subtitle: Text(
              'Stock: ${aliment.quantiteStock} ${aliment.uniteSecondaire ?? aliment.unite}\n'
              'Prix: ${aliment.prixUnitaire} ${aliment.devise}/100${aliment.unite}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _ajouterOuModifierAliment(aliment),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _supprimerAliment(aliment.id),
                ),
                IconButton(
                  icon: const Icon(Icons.inventory),
                  onPressed: () => _ajusterStock(aliment),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AlimentDialog extends StatefulWidget {
  final Aliment? aliment;

  const AlimentDialog({super.key, this.aliment});

  @override
  State<AlimentDialog> createState() => _AlimentDialogState();
}

class _AlimentDialogState extends State<AlimentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantiteStockController;
  late TextEditingController _seuilAlerteController;
  late TextEditingController _uniteController;
  late TextEditingController _uniteSecondaireController;
  late TextEditingController _facteurConversionController;
  late TextEditingController _quantiteAchatController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinesController;
  late TextEditingController _lipidesController;
  late TextEditingController _glucidesController;
  late TextEditingController _fibresController;
  late TextEditingController _eauController;
  late TextEditingController _prixUnitaireController;
  late TextEditingController _deviseController;
  late TextEditingController _decrementationJournaliereController;
  bool _gestionParPortion = false;
  bool _gestionStock = false;
  bool _autoDecrementation = false;

  @override
  void initState() {
    super.initState();
    final aliment = widget.aliment;
    _nomController = TextEditingController(text: aliment?.nom ?? '');
    _descriptionController = TextEditingController(text: aliment?.description ?? '');
    _quantiteStockController = TextEditingController(
      text: aliment?.quantiteStock.toString() ?? '0',
    );
    _seuilAlerteController = TextEditingController(
      text: aliment?.seuilAlerte.toString() ?? '0',
    );
    _uniteController = TextEditingController(text: aliment?.unite ?? 'g');
    _uniteSecondaireController = TextEditingController(text: aliment?.uniteSecondaire ?? '');
    _facteurConversionController = TextEditingController(
      text: aliment?.facteurConversion?.toString() ?? '',
    );
    _quantiteAchatController = TextEditingController(
      text: aliment?.quantiteAchatParDefaut.toString() ?? '0',
    );
    _caloriesController = TextEditingController(
      text: aliment?.calories.toString() ?? '0',
    );
    _proteinesController = TextEditingController(
      text: aliment?.proteines.toString() ?? '0',
    );
    _lipidesController = TextEditingController(
      text: aliment?.lipides.toString() ?? '0',
    );
    _glucidesController = TextEditingController(
      text: aliment?.glucides.toString() ?? '0',
    );
    _fibresController = TextEditingController(
      text: aliment?.fibres.toString() ?? '0',
    );
    _eauController = TextEditingController(
      text: aliment?.eau.toString() ?? '0',
    );
    _prixUnitaireController = TextEditingController(
      text: aliment?.prixUnitaire.toString() ?? '0',
    );
    _deviseController = TextEditingController(text: aliment?.devise ?? 'EUR');
    _decrementationJournaliereController = TextEditingController(
      text: aliment?.decrementationJournaliere?.toString() ?? '',
    );

    // Initialiser les états
    _gestionParPortion = aliment?.uniteSecondaire?.isNotEmpty == true;
    _gestionStock = aliment?.gestionStock ?? false;
    _autoDecrementation = aliment?.decrementationJournaliere != null;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _quantiteStockController.dispose();
    _seuilAlerteController.dispose();
    _uniteController.dispose();
    _uniteSecondaireController.dispose();
    _facteurConversionController.dispose();
    _quantiteAchatController.dispose();
    _caloriesController.dispose();
    _proteinesController.dispose();
    _lipidesController.dispose();
    _glucidesController.dispose();
    _fibresController.dispose();
    _eauController.dispose();
    _prixUnitaireController.dispose();
    _deviseController.dispose();
    _decrementationJournaliereController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                      widget.aliment == null ? 'Ajouter un aliment' : 'Modifier l\'aliment',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const TabBar(
                      tabs: [
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
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      children: [
                        // Onglet Aliment
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nomController,
                                decoration: InputDecoration(
                                  labelText: 'Nom *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) =>
                                    value?.isEmpty == true ? 'Ce champ est requis' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _uniteController.text,
                                      decoration: InputDecoration(
                                        labelText: 'Unité principale *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'g', child: Text('Grammes (g)')),
                                        DropdownMenuItem(value: 'ml', child: Text('Millilitres (ml)')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _uniteController.text = value;
                                          });
                                        }
                                      },
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Ce champ est requis' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Les valeurs nutritionnelles sont toujours exprimées pour 100${_uniteController.text}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                elevation: 0,
                                color: Colors.blue[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mode de gestion',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: AppTheme.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          children: [
                                            ListTile(
                                              title: const Text('Par poids/volume'),
                                              leading: Radio<bool>(
                                                value: false,
                                                groupValue: _gestionParPortion,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _gestionParPortion = value!;
                                                    if (!_gestionParPortion) {
                                                      _uniteSecondaireController.clear();
                                                      _facteurConversionController.clear();
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            Divider(height: 1, color: Colors.grey[300]),
                                            ListTile(
                                              title: const Text('Par portion'),
                                              leading: Radio<bool>(
                                                value: true,
                                                groupValue: _gestionParPortion,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _gestionParPortion = value!;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_gestionParPortion) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Définissez l\'unité de portion et son équivalent en ${_uniteController.text}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _uniteSecondaireController,
                                                decoration: InputDecoration(
                                                  labelText: 'Nom de la portion',
                                                  hintText: 'ex: œuf, tranche, boîte',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                                validator: (value) {
                                                  if (_gestionParPortion && value?.isEmpty == true) {
                                                    return 'Requis en mode portion';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _facteurConversionController,
                                                decoration: InputDecoration(
                                                  labelText: '1 portion équivaut à',
                                                  hintText: 'ex: 50',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  suffixText: _uniteController.text,
                                                ),
                                                keyboardType: TextInputType.number,
                                                validator: (value) {
                                                  if (_gestionParPortion && value?.isEmpty == true) {
                                                    return 'Requis en mode portion';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _prixUnitaireController,
                                      decoration: InputDecoration(
                                        labelText: 'Prix',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Ce champ est requis' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      controller: _deviseController,
                                      decoration: InputDecoration(
                                        labelText: 'Devise',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Requis' : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Onglet Nutrition
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                'Valeurs pour 100${_uniteController.text}',
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
                                      decoration: InputDecoration(
                                        labelText: 'Calories *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Requis' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _proteinesController,
                                      decoration: InputDecoration(
                                        labelText: 'Protéines *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        suffixText: 'g',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Requis' : null,
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
                                      decoration: InputDecoration(
                                        labelText: 'Lipides *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        suffixText: 'g',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Requis' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _glucidesController,
                                      decoration: InputDecoration(
                                        labelText: 'Glucides *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        suffixText: 'g',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Requis' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _fibresController,
                                      decoration: InputDecoration(
                                        labelText: 'Fibres',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        suffixText: 'g',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _eauController,
                                      decoration: InputDecoration(
                                        labelText: 'Eau',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        suffixText: 'g',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Onglet Stock
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                'Gestion du stock',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Gestion du stock',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  Switch(
                                    value: _gestionStock,
                                    onChanged: (value) {
                                      setState(() {
                                        _gestionStock = value;
                                        if (!_gestionStock) {
                                          _autoDecrementation = false;
                                          _quantiteStockController.text = '0';
                                          _seuilAlerteController.text = '0';
                                          _quantiteAchatController.text = '0';
                                          _decrementationJournaliereController.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_gestionStock) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _quantiteStockController,
                                        decoration: InputDecoration(
                                          labelText: 'Quantité en stock *',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          suffixText: _uniteSecondaireController.text.isNotEmpty 
                                              ? _uniteSecondaireController.text 
                                              : _uniteController.text,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) =>
                                            _gestionStock && value?.isEmpty == true ? 'Ce champ est requis' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _seuilAlerteController,
                                        decoration: InputDecoration(
                                          labelText: 'Seuil d\'alerte *',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          suffixText: _uniteSecondaireController.text.isNotEmpty 
                                              ? _uniteSecondaireController.text 
                                              : _uniteController.text,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) =>
                                            _gestionStock && value?.isEmpty == true ? 'Ce champ est requis' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _quantiteAchatController,
                                  decoration: InputDecoration(
                                    labelText: 'Quantité d\'achat par défaut *',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixText: _uniteSecondaireController.text.isNotEmpty 
                                        ? _uniteSecondaireController.text 
                                        : _uniteController.text,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) =>
                                      _gestionStock && value?.isEmpty == true ? 'Ce champ est requis' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Auto-décrémentation journalière',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                    Switch(
                                      value: _autoDecrementation,
                                      onChanged: (value) {
                                        setState(() {
                                          _autoDecrementation = value;
                                          if (!_autoDecrementation) {
                                            _decrementationJournaliereController.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_autoDecrementation) ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _decrementationJournaliereController,
                                    decoration: InputDecoration(
                                      labelText: 'Quantité à décrémenter par jour *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      suffixText: _uniteSecondaireController.text.isNotEmpty 
                                          ? _uniteSecondaireController.text 
                                          : _uniteController.text,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) =>
                                        _autoDecrementation && value?.isEmpty == true ? 'Ce champ est requis' : null,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() == true) {
                          final aliment = Aliment(
                            id: widget.aliment?.id ?? const Uuid().v4(),
                            nom: _nomController.text,
                            description: _descriptionController.text,
                            gestionStock: _gestionStock,
                            quantiteStock: double.parse(_quantiteStockController.text),
                            seuilAlerte: double.parse(_seuilAlerteController.text),
                            unite: _uniteController.text,
                            uniteSecondaire: _uniteSecondaireController.text.isEmpty
                                ? null
                                : _uniteSecondaireController.text,
                            facteurConversion: _facteurConversionController.text.isEmpty
                                ? null
                                : double.tryParse(_facteurConversionController.text),
                            quantiteAchatParDefaut: double.parse(_quantiteAchatController.text),
                            calories: double.parse(_caloriesController.text),
                            proteines: double.parse(_proteinesController.text),
                            lipides: double.parse(_lipidesController.text),
                            glucides: double.parse(_glucidesController.text),
                            fibres: double.parse(_fibresController.text),
                            eau: double.parse(_eauController.text),
                            prixUnitaire: double.parse(_prixUnitaireController.text),
                            devise: _deviseController.text,
                            decrementationJournaliere: _autoDecrementation
                                ? double.tryParse(_decrementationJournaliereController.text)
                                : null,
                          );
                          Navigator.pop(context, aliment);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Enregistrer'),
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
}

class AjustementStockDialog extends StatefulWidget {
  final Aliment aliment;

  const AjustementStockDialog({super.key, required this.aliment});

  @override
  State<AjustementStockDialog> createState() => _AjustementStockDialogState();
}

class _AjustementStockDialogState extends State<AjustementStockDialog> {
  final _controller = TextEditingController();
  bool _isAddition = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajuster le stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stock actuel: ${widget.aliment.quantiteStock} ${widget.aliment.uniteSecondaire ?? widget.aliment.unite}',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Opération:'),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ajouter'),
                selected: _isAddition,
                onSelected: (selected) {
                  if (selected) setState(() => _isAddition = true);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Retirer'),
                selected: !_isAddition,
                onSelected: (selected) {
                  if (selected) setState(() => _isAddition = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Quantité à ${_isAddition ? 'ajouter' : 'retirer'}',
              suffixText: widget.aliment.uniteSecondaire ?? widget.aliment.unite,
            ),
            keyboardType: TextInputType.number,
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
            final quantite = double.tryParse(_controller.text);
            if (quantite != null) {
              Navigator.pop(context, _isAddition ? quantite : -quantite);
            }
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
} 
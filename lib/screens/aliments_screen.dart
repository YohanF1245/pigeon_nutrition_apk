import 'package:flutter/material.dart';
import '../models/aliment.dart';
import '../services/aliment_service.dart';
import '../widgets/aliment_dialog.dart';
import 'package:logging/logging.dart';
import '../widgets/aliment_card.dart';

class AlimentsScreen extends StatefulWidget {
  const AlimentsScreen({super.key});

  @override
  State<AlimentsScreen> createState() => _AlimentsScreenState();
}

class _AlimentsScreenState extends State<AlimentsScreen> {
  final AlimentService _alimentService = AlimentService();
  final _logger = Logger('AlimentsScreen');
  List<Aliment> _aliments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerAliments();
  }

  Future<void> _chargerAliments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final aliments = await _alimentService.getAllAliments();
      if (!mounted) return;
      setState(() {
        _aliments = aliments;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Erreur lors du chargement des aliments: $e');
      if (!mounted) return;
      setState(() {
        _aliments = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _ajouterOuModifierAliment(Aliment? aliment) async {
    try {
      final nouvelAliment = await AlimentDialog.show(context, aliment: aliment);
      if (nouvelAliment != null) {
        try {
          await _alimentService.insertAliment(nouvelAliment);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aliment enregistré avec succès')),
          );
          await _chargerAliments();
        } catch (e) {
          _logger.severe('Erreur lors de la sauvegarde: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la sauvegarde: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.severe('Erreur lors de l\'affichage du dialogue: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'affichage du dialogue: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _ajouterAliment() {
    _ajouterOuModifierAliment(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_aliments.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.no_food,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun aliment',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez des aliments pour commencer',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _ajouterAliment,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un aliment'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _ajouterAliment,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _aliments.length,
        itemBuilder: (context, index) {
          final aliment = _aliments[index];
          return AlimentCard(
            aliment: aliment,
            onModified: _chargerAliments,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterAliment,
        child: const Icon(Icons.add),
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
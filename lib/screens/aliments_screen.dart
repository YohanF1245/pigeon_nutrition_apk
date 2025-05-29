import 'package:flutter/material.dart';
import '../models/aliment.dart';
import '../models/repas.dart';
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

  Future<void> _supprimerAliment(Aliment aliment) async {
    // Vérifier si l'aliment est utilisé dans des repas
    final repasUtilisantAliment = await _alimentService.getRepasUtilisantAliment(aliment.id);
    if (!mounted) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer "${aliment.nom}" ?'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'Valeurs nutritionnelles :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Calories', style: TextStyle(color: Colors.blue)),
                            Text(
                              '${aliment.calories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Protéines', style: TextStyle(color: Colors.red)),
                            Text(
                              '${aliment.proteines.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Lipides', style: TextStyle(color: Colors.orange)),
                            Text(
                              '${aliment.lipides.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Glucides', style: TextStyle(color: Colors.green)),
                            Text(
                              '${aliment.glucides.toStringAsFixed(1)}g',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (repasUtilisantAliment.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Attention : Cet aliment est utilisé dans ${repasUtilisantAliment.length} repas.',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La suppression de cet aliment affectera les repas suivants :',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.2,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: repasUtilisantAliment.map((repas) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• ${repas.nom}'),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        await _alimentService.deleteAliment(aliment.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aliment supprimé avec succès'),
          ),
        );
        _chargerAliments();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _ajouterAliment() async {
    final result = await AlimentDialog.show(context);
    
    if (result != null) {
      try {
        await _alimentService.insertAliment(result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aliment ajouté avec succès'),
          ),
        );
        _chargerAliments();
      } catch (e) {
        _logger.severe('Erreur lors de l\'ajout de l\'aliment: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
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
            onDelete: () => _supprimerAliment(aliment),
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
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajuster le stock',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stock actuel: ${widget.aliment.getStockDisplay()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text('Opération:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ChoiceChip(
                  label: const Text('Ajouter'),
                  selected: _isAddition,
                  onSelected: (selected) {
                    if (selected) setState(() => _isAddition = true);
                  },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Retirer'),
                  selected: !_isAddition,
                  onSelected: (selected) {
                    if (selected) setState(() => _isAddition = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Quantité à ${_isAddition ? 'ajouter' : 'retirer'}',
                suffixText: widget.aliment.unitePortionLabel ?? widget.aliment.unite.symbole,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final quantite = double.tryParse(_controller.text);
                    if (quantite != null && quantite > 0) {
                      Navigator.pop(context, _isAddition ? quantite : -quantite);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer une quantité valide'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
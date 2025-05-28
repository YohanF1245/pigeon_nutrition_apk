import 'package:flutter/material.dart';
import '../models/aliment.dart';

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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: ChoiceChip(
                      label: const Text('Ajouter'),
                      selected: _isAddition,
                      onSelected: (selected) {
                        if (selected) setState(() => _isAddition = true);
                      },
                      labelStyle: TextStyle(
                        color: _isAddition ? Colors.white : Colors.black,
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: ChoiceChip(
                      label: const Text('Retirer'),
                      selected: !_isAddition,
                      onSelected: (selected) {
                        if (selected) setState(() => _isAddition = false);
                      },
                      labelStyle: TextStyle(
                        color: !_isAddition ? Colors.white : Colors.black,
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                    ),
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
      ),
    );
  }
} 
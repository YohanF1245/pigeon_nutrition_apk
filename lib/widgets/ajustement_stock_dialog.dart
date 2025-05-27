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
    return AlertDialog(
      title: const Text('Ajuster le stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stock actuel: ${widget.aliment.quantiteStock} ${widget.aliment.uniteSecondaire ?? widget.aliment.unite.symbole}',
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
              suffixText: widget.aliment.uniteSecondaire ?? widget.aliment.unite.symbole,
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
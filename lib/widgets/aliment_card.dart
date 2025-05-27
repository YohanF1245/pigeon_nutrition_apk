import 'package:flutter/material.dart';
import '../models/aliment.dart';
import '../services/aliment_service.dart';
import '../widgets/aliment_dialog.dart';
import '../widgets/ajustement_stock_dialog.dart';

class AlimentCard extends StatelessWidget {
  final Aliment aliment;
  final VoidCallback onModified;
  final AlimentService _alimentService = AlimentService();

  AlimentCard({
    super.key,
    required this.aliment,
    required this.onModified,
  });

  Future<void> _modifierAliment(BuildContext context) async {
    final result = await AlimentDialog.show(context, aliment: aliment);
    if (result != null) {
      await _alimentService.updateAliment(result);
      onModified();
    }
  }

  Future<void> _supprimerAliment(BuildContext context) async {
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
      await _alimentService.deleteAliment(aliment.id);
      onModified();
    }
  }

  Future<void> _ajusterStock(BuildContext context) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AjustementStockDialog(aliment: aliment),
    );

    if (result != null) {
      await _alimentService.ajusterStock(aliment.id, result);
      onModified();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
      child: ListTile(
        title: Text(aliment.nom),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock: ${aliment.quantiteStock} ${aliment.uniteSecondaire ?? aliment.unite}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Prix: ${aliment.prixUnitaire} ${aliment.devise}/100${aliment.unite}',
              style: const TextStyle(fontSize: 14),
            ),
            if (aliment.stockBas)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Stock bas',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _modifierAliment(context);
                break;
              case 'delete':
                _supprimerAliment(context);
                break;
              case 'stock':
                _ajusterStock(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stock',
              child: Row(
                children: [
                  Icon(Icons.inventory),
                  SizedBox(width: 8),
                  Text('Ajuster le stock'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
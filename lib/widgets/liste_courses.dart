import 'package:flutter/material.dart';
import '../models/aliment.dart';
import '../services/aliment_service.dart';

class ListeCourses extends StatefulWidget {
  final Map<String, bool>? initialCheckedState;
  final Function(Map<String, bool>)? onCheckedStateChanged;
  final bool isDrawer;
  final VoidCallback? onClose;

  const ListeCourses({
    super.key,
    this.initialCheckedState,
    this.onCheckedStateChanged,
    this.isDrawer = false,
    this.onClose,
  });

  @override
  State<ListeCourses> createState() => _ListeCoursesState();
}

class _ListeCoursesState extends State<ListeCourses> {
  final _alimentService = AlimentService();
  late final Map<String, bool> _itemsChecked;
  List<Aliment> _alimentsEnRupture = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _itemsChecked = Map<String, bool>.from(widget.initialCheckedState ?? {});
    _chargerAliments();
  }

  Future<void> _chargerAliments() async {
    setState(() => _isLoading = true);
    try {
      final aliments = await _alimentService.getAlimentsEnRupture();
      setState(() {
        _alimentsEnRupture = aliments;
        // Initialiser les cases à cocher seulement pour les nouveaux aliments
        for (var aliment in aliments) {
          _itemsChecked.putIfAbsent(aliment.id, () => false);
        }
        // Nettoyer les aliments qui ne sont plus en rupture
        _itemsChecked.removeWhere(
          (id, _) => !aliments.any((a) => a.id == id)
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateCheckedState(String id, bool? value) {
    setState(() {
      _itemsChecked[id] = value ?? false;
      widget.onCheckedStateChanged?.call(_itemsChecked);
    });
  }

  int get _itemsRestants => _alimentsEnRupture.where((a) => !(_itemsChecked[a.id] ?? false)).length;
  bool get _toutEstCoche => _itemsRestants == 0 && _alimentsEnRupture.isNotEmpty;

  Widget _buildTitle() {
    return const Text('Liste de courses');
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _alimentsEnRupture.length,
      itemBuilder: (context, index) {
        final aliment = _alimentsEnRupture[index];
        return CheckboxListTile(
          value: _itemsChecked[aliment.id] ?? false,
          onChanged: (bool? value) {
            _updateCheckedState(aliment.id, value);
          },
          title: Text(aliment.nom),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock: ${aliment.getStockDisplay()}',
                style: const TextStyle(color: Colors.orange),
              ),
              Text(
                'À acheter: ${aliment.quantiteAchatParDefaut.toStringAsFixed(0)} ${aliment.unitePortionLabel ?? aliment.unite.symbole}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          secondary: IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // TODO: Implémenter l'achat rapide
            },
            tooltip: 'Achat rapide',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_alimentsEnRupture.isEmpty) {
      return const Center(
        child: Text(
          'Aucun aliment à acheter',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (widget.isDrawer) {
      return Column(
        children: [
          AppBar(
            title: _buildTitle(),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ),
          Expanded(
            child: _buildListView(),
          ),
        ],
      );
    }

    return _buildListView();
  }
} 
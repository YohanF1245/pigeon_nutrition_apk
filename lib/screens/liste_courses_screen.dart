import 'package:flutter/material.dart';
import '../services/aliment_service.dart';

class ListeCoursesScreen extends StatefulWidget {
  final VoidCallback? onClose;

  const ListeCoursesScreen({
    super.key,
    this.onClose,
  });

  @override
  State<ListeCoursesScreen> createState() => _ListeCoursesScreenState();
}

class _ListeCoursesScreenState extends State<ListeCoursesScreen> {
  final AlimentService _alimentService = AlimentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _listeCourses = [];
  double _coutTotal = 0;

  @override
  void initState() {
    super.initState();
    _chargerListeCourses();
  }

  Future<void> _chargerListeCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final liste = await _alimentService.getListeCourses();
      if (!mounted) return;
      double total = 0;
      for (var item in liste) {
        total += double.parse(item['coutEstime'] ?? '0.00');
      }
      setState(() {
        _listeCourses = liste;
        _coutTotal = total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('Erreur lors du chargement de la liste: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement de la liste: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste de courses'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: const [
              // TODO: Implémenter la liste des aliments à acheter
            ],
          ),
    );
  }
} 
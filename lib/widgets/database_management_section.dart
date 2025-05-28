import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/database_service.dart';
import 'package:path/path.dart' as path;

class DatabaseManagementSection extends StatelessWidget {
  final _databaseService = DatabaseService();

  DatabaseManagementSection({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      // Obtenir le chemin de la base de données
      final dbPath = await _databaseService.getDatabasePath();
      final dbFile = File(dbPath);
      
      // Créer une copie temporaire avec un nom plus explicite
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final tempFile = File(path.join(tempDir.path, 'pigeon_nutrition_backup_$timestamp.db'));
      await dbFile.copy(tempFile.path);

      // Partager le fichier
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Sauvegarde Pigeon Nutrition',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de données exportée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    try {
      // Sélectionner le fichier
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Sélectionner une sauvegarde Pigeon Nutrition',
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      
      // Vérifier l'extension du fichier
      if (!file.path.toLowerCase().endsWith('.db')) {
        throw Exception('Le fichier doit avoir l\'extension .db');
      }

      final dbPath = await _databaseService.getDatabasePath();

      // Vérifier que c'est bien une base SQLite
      final bytes = await file.readAsBytes();
      if (bytes.length < 16 || 
          String.fromCharCodes(bytes.sublist(0, 16)) != 'SQLite format 3\x00') {
        throw Exception('Format de fichier invalide');
      }

      // Fermer la connexion à la base de données
      await _databaseService.close();

      // Remplacer la base de données
      await file.copy(dbPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de données importée avec succès. Redémarrez l\'application.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion de la base de données',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sauvegardez ou restaurez vos données (aliments, repas, mesures...)',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportDatabase(context),
                    icon: const Icon(Icons.upload),
                    label: const Text('Exporter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _importDatabase(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Importer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
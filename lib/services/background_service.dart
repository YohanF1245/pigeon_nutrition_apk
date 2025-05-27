import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'aliment_service.dart';

class BackgroundService {
  static const String taskName = 'decrementationJournaliere';
  static const String lastRunKey = 'lastDecrementationRun';

  static Future<void> initialize() async {
    // Ne pas initialiser sur le web
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    }
  }

  static Future<void> registerTask() async {
    // Ne pas enregistrer la tâche sur le web
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Workmanager().registerPeriodicTask(
        'decrementationStock',
        taskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == BackgroundService.taskName) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastRun = prefs.getInt(BackgroundService.lastRunKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Vérifier si la dernière exécution date d'au moins 20 heures
        if (now - lastRun >= const Duration(hours: 20).inMilliseconds) {
          final alimentService = AlimentService();
          final aliments = await alimentService.getAllAliments();
          
          for (final aliment in aliments) {
            if (aliment.gestionStock && aliment.decrementationJournaliere != null) {
              final nouvelleQuantite = aliment.quantiteStock - aliment.decrementationJournaliere!;
              aliment.quantiteStock = nouvelleQuantite < 0 ? 0 : nouvelleQuantite;
              await alimentService.updateAliment(aliment);
            }
          }
          
          // Sauvegarder l'heure de la dernière exécution
          await prefs.setInt(BackgroundService.lastRunKey, now);
        }
      } catch (e) {
        print('Erreur lors de la décrémentation automatique: $e');
      }
    }
    return true;
  });
} 
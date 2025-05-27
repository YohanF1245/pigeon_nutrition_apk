import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'aliment_service.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class BackgroundService {
  static final _logger = Logger('BackgroundService');
  static const String lastRunKey = 'lastDecrementationRun';
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      _logger.info('Initialisation du service de notifications...');
      
      if (!kIsWeb) {
        // Initialiser timezone
        tz.initializeTimeZones();
        final local = tz.getLocation('Europe/Paris');
        tz.setLocalLocation(local);
        
        // Initialiser les notifications
        const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
        
        await _notifications.initialize(initializationSettings);
        
        // Planifier la vérification quotidienne
        await _scheduleStockCheck();
      }
    } catch (e) {
      _logger.severe('Erreur lors de l\'initialisation du service de notifications: $e');
      rethrow;
    }
  }

  static Future<void> _scheduleStockCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getInt(lastRunKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Vérifier si la dernière exécution date d'au moins 20 heures
      if (now - lastRun >= const Duration(hours: 20).inMilliseconds) {
        final alimentService = AlimentService();
        final aliments = await alimentService.getAliments();
        
        for (final aliment in aliments) {
          if (aliment.gestionStock && aliment.decrementationJournaliere != null) {
            final nouvelleQuantite = aliment.quantiteStock - aliment.decrementationJournaliere!;
            aliment.quantiteStock = nouvelleQuantite < 0 ? 0 : nouvelleQuantite;
            await alimentService.updateAliment(aliment);
            
            // Vérifier si le stock est bas
            if (aliment.seuilAlerte != null && aliment.quantiteStock <= aliment.seuilAlerte!) {
              await _showStockAlert(aliment.nom, aliment.quantiteStock);
            }
          }
        }
        
        // Sauvegarder l'heure de la dernière exécution
        await prefs.setInt(lastRunKey, now);
      }
      
      // Planifier la prochaine vérification dans 24 heures
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final scheduledDate = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        8, // Exécuter à 8h du matin
        0,
      );
      
      final location = tz.getLocation('Europe/Paris');
      final scheduledDateTime = tz.TZDateTime.from(scheduledDate, location);
      
      await _notifications.zonedSchedule(
        0,
        'Vérification des stocks',
        'Vérification quotidienne des stocks d\'aliments',
        scheduledDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'stock_check',
            'Vérification des stocks',
            channelDescription: 'Canal pour les vérifications quotidiennes des stocks',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      _logger.severe('Erreur lors de la vérification des stocks: $e');
    }
  }

  static Future<void> _showStockAlert(String nomAliment, double quantite) async {
    await _notifications.show(
      1, // ID différent pour les alertes de stock
      'Stock bas',
      'Le stock de $nomAliment est bas (${quantite.toStringAsFixed(2)})',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'stock_alert',
          'Alertes de stock',
          channelDescription: 'Canal pour les alertes de stock bas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
} 
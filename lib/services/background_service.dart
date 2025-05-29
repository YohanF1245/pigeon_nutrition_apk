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
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.info('Initialisation du service de notifications...');
      
      if (!kIsWeb) {
        // Initialiser les notifications de manière asynchrone
        _initializeNotifications();
        
        // Planifier la vérification quotidienne
        _scheduleStockCheck();
      }
      
      _isInitialized = true;
    } catch (e) {
      _logger.severe('Erreur lors de l\'initialisation du service de notifications: $e');
      // Ne pas relancer l'erreur pour éviter de bloquer l'application
    }
  }

  static Future<void> _initializeNotifications() async {
    try {
      // Initialiser timezone en arrière-plan
      await Future(() async {
        tz.initializeTimeZones();
        final local = tz.getLocation('Europe/Paris');
        tz.setLocalLocation(local);
      });
      
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      
      await _notifications.initialize(initializationSettings);
    } catch (e) {
      _logger.warning('Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  static Future<void> _scheduleStockCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getInt(lastRunKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Vérifier si la dernière exécution date d'au moins 20 heures
      if (now - lastRun >= const Duration(hours: 20).inMilliseconds) {
        _checkStocks();
        
        // Sauvegarder l'heure de la dernière exécution
        await prefs.setInt(lastRunKey, now);
      }
      
      // Planifier la prochaine vérification
      _scheduleNextCheck();
    } catch (e) {
      _logger.warning('Erreur lors de la planification de la vérification des stocks: $e');
    }
  }

  static Future<void> _checkStocks() async {
    try {
      final alimentService = AlimentService();
      final aliments = await alimentService.getAliments();
      
      for (final aliment in aliments) {
        if (aliment.gestionStock && aliment.decrementationJournaliere != null) {
          final nouvelleQuantite = aliment.quantiteStock - aliment.decrementationJournaliere!;
          aliment.quantiteStock = nouvelleQuantite < 0 ? 0 : nouvelleQuantite;
          await alimentService.updateAliment(aliment);
          
          // Vérifier si le stock est bas
          if (aliment.seuilAlerte != null && aliment.quantiteStock <= aliment.seuilAlerte!) {
            _showStockAlert(aliment.nom, aliment.quantiteStock);
          }
        }
      }
    } catch (e) {
      _logger.warning('Erreur lors de la vérification des stocks: $e');
    }
  }

  static Future<void> _scheduleNextCheck() async {
    try {
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
      _logger.warning('Erreur lors de la planification de la prochaine vérification: $e');
    }
  }

  static Future<void> _showStockAlert(String nomAliment, double quantite) async {
    try {
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
    } catch (e) {
      _logger.warning('Erreur lors de l\'affichage de l\'alerte de stock: $e');
    }
  }
} 
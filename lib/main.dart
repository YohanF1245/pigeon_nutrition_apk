import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'services/aliment_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/aliments_screen.dart';
import 'screens/repas_screen.dart';
import 'screens/entrainements_screen.dart';
import 'screens/mesures_screen.dart';
import 'screens/parametres_nutritionnels_screen.dart';

void main() async {
  try {
    print('Démarrage de l\'application...');
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialisé');

    // Initialisation de SQLite selon la plateforme
    if (kIsWeb) {
      print('Configuration SQLite pour le web...');
      databaseFactory = databaseFactoryFfiWeb;
      print('Factory SQLite web configurée');
    } else {
      print('Configuration SQLite pour Android...');
      sqfliteFfiInit();
      print('SQLite Android initialisé');
    }

    // Initialisation du service
    print('Initialisation du service Aliment...');
    final alimentService = AlimentService();
    await alimentService.initialize();
    print('Service Aliment initialisé');

    print('Lancement de l\'application...');
    runApp(const MyApp());
    print('Application lancée');
  } catch (e, stackTrace) {
    print('Erreur lors du démarrage: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pigeon Nutrition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B5998), // Bleu Facebook-like
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<({Widget screen, String title, IconData icon})> _screens = [
    (
      screen: const DashboardScreen(),
      title: 'Tableau de bord',
      icon: Icons.dashboard,
    ),
    (
      screen: const AlimentsScreen(),
      title: 'Aliments',
      icon: Icons.food_bank,
    ),
    (
      screen: const RepasScreen(),
      title: 'Repas',
      icon: Icons.restaurant,
    ),
    (
      screen: const EntrainementsScreen(),
      title: 'Entraînements',
      icon: Icons.fitness_center,
    ),
    (
      screen: const MesuresScreen(),
      title: 'Mesures',
      icon: Icons.monitor_weight,
    ),
    (
      screen: const ParametresNutritionnelsScreen(),
      title: 'Paramètres Nutritionnels',
      icon: Icons.settings,
    ),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _screens[_selectedIndex];
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(currentScreen.title),
        actions: [
          if (_selectedIndex != 5) // N'affiche pas l'icône des paramètres quand on est déjà sur les paramètres
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _onItemSelected(5),
            ),
        ],
      ),
      body: currentScreen.screen,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _screens.take(5).map((screen) => BottomNavigationBarItem(
          icon: Icon(screen.icon),
          label: screen.title.split(' ')[0], // Prend juste le premier mot pour la bottom bar
        )).toList(),
        currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onTap: _onItemSelected,
      ),
      floatingActionButton: (_selectedIndex == 1) ? FloatingActionButton(
        onPressed: () {
          // TODO: Ajouter la logique pour ajouter un aliment
        },
        backgroundColor: const Color(0xFF00897B),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un aliment',
      ) : null,
    );
  }
}

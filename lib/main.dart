import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/background_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/aliments_screen.dart';
import 'screens/repas_screen.dart';
import 'screens/entrainements_screen.dart';
import 'screens/mesures_screen.dart';
import 'screens/parametres_nutritionnels_screen.dart';
import 'screens/liste_courses_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration du logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final logger = Logger('main');
  try {
    logger.info('Démarrage de l\'application...');
    
    // Initialiser le service en arrière-plan
    await BackgroundService.initialize();
    
    runApp(const MyApp());
  } catch (e) {
    logger.severe('Erreur lors du démarrage de l\'application: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pigeon Nutrition',
      theme: AppTheme.theme,
      home: const MainScreen(),
      routes: {
        '/parametres': (context) => const ParametresNutritionnelsScreen(),
      },
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
  bool _showListeCourses = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AlimentsScreen(),
    const RepasScreen(),
    const EntrainementsScreen(),
    const MesuresScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Tableau de bord',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.food_bank),
      label: 'Aliments',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.restaurant),
      label: 'Repas',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: 'Entraînements',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.monitor_weight),
      label: 'Mesures',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Cacher la liste de courses si on change d'écran
      _showListeCourses = false;
    });
  }

  void _toggleListeCourses() {
    setState(() {
      _showListeCourses = !_showListeCourses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pigeon Nutrition'),
        actions: [
          if (_selectedIndex == 0) // Afficher l'icône de liste de courses uniquement sur le dashboard
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: _toggleListeCourses,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const ParametresNutritionnelsScreen()),
              );
              if (result == true && _selectedIndex == 0) {
                setState(() {
                  // Recréer le dashboard pour forcer un rafraîchissement complet
                  _screens[0] = const DashboardScreen();
                });
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_showListeCourses)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.8,
              child: Card(
                margin: EdgeInsets.zero,
                child: ListeCoursesScreen(
                  onClose: _toggleListeCourses,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

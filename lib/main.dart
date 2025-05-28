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
import 'screens/splash_screen.dart';
import 'widgets/liste_courses.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/repas_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation des services
  final databaseService = DatabaseService();
  final repasService = RepasService();
  await databaseService.initializeDatabase();
  await repasService.initialiserTable();
  
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
      title: 'Pigeon Fitness',
      theme: AppTheme.theme,
      home: const SplashScreenWrapper(),
      routes: {
        '/parametres': (context) => const ParametresNutritionnelsScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
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
  List<dynamic> _alimentsEnRupture = [];
  late final List<Widget> _screens;
  final Map<String, bool> _listeCoursesCheckedState = {};

  int get _itemsRestants => _alimentsEnRupture.where((a) => !(_listeCoursesCheckedState[a.id] ?? false)).length;
  bool get _toutEstCoche => _itemsRestants == 0 && _alimentsEnRupture.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onAlimentsEnRuptureChanged: (aliments) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _alimentsEnRupture = aliments;
              });
            }
          });
        },
      ),
      const AlimentsScreen(),
      const RepasScreen(),
      const EntrainementsScreen(),
      const MesuresScreen(),
    ];
  }

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

  void updateAlimentsEnRupture(List<dynamic> aliments) {
    setState(() {
      _alimentsEnRupture = aliments;
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
              icon: Stack(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: _toutEstCoche ? Colors.green : null,
                  ),
                  if (_itemsRestants > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$_itemsRestants',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_toutEstCoche)
                    const Positioned(
                      right: -5,
                      bottom: -5,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                ],
              ),
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
                  _screens[0] = DashboardScreen(
                    onAlimentsEnRuptureChanged: (aliments) {
                      Future.microtask(() {
                        if (mounted) {
                          setState(() {
                            _alimentsEnRupture = aliments;
                          });
                        }
                      });
                    },
                  );
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
                child: ListeCourses(
                  initialCheckedState: _listeCoursesCheckedState,
                  onCheckedStateChanged: (newState) {
                    setState(() {
                      _listeCoursesCheckedState.clear();
                      _listeCoursesCheckedState.addAll(newState);
                    });
                  },
                  isDrawer: true,
                  onClose: _toggleListeCourses,
                  onStockUpdated: () {
                    // Vider d'abord l'état des cases cochées
                    _listeCoursesCheckedState.clear();
                    
                    // Mettre à jour le dashboard et les aliments en une seule fois
                    setState(() {
                      _screens[0] = DashboardScreen(
                        onAlimentsEnRuptureChanged: (aliments) {
                          if (mounted) {
                            setState(() {
                              _alimentsEnRupture = aliments;
                            });
                          }
                        },
                      );
                      // Forcer la mise à jour immédiate des aliments en rupture
                      _alimentsEnRupture = [];
                    });
                  },
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

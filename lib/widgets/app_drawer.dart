import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/aliments_screen.dart';
import '../screens/repas_screen.dart';
import '../screens/entrainements_screen.dart';
import '../screens/mesures_screen.dart';
import '../screens/parametres_nutritionnels_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.lightBlue,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nutrition Pigeon',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.dashboard,
              title: 'Tableau de bord',
              route: '/',
            ),
            _buildMenuItem(
              context,
              icon: Icons.restaurant,
              title: 'Aliments',
              route: '/aliments',
            ),
            _buildMenuItem(
              context,
              icon: Icons.schedule,
              title: 'Repas',
              route: '/repas',
            ),
            _buildMenuItem(
              context,
              icon: Icons.fitness_center,
              title: 'Entraînements',
              route: '/entrainements',
            ),
            _buildMenuItem(
              context,
              icon: Icons.monitor_weight,
              title: 'Mesures',
              route: '/mesures',
            ),
            const Divider(),
            _buildMenuItem(
              context,
              icon: Icons.settings,
              title: 'Paramètres Nutritionnels',
              route: '/parametres_nutritionnels',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.accentBlue : AppTheme.darkBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.accentBlue : AppTheme.darkBlue,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Ferme le drawer
        if (currentRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      tileColor: isSelected ? AppTheme.lightBlue.withOpacity(0.5) : null,
    );
  }
} 
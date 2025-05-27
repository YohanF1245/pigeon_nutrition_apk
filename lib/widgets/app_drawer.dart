import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard,
            title: 'Tableau de bord',
            index: 0,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.restaurant,
            title: 'Aliments',
            index: 1,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.schedule,
            title: 'Repas',
            index: 2,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.fitness_center,
            title: 'Entraînements',
            index: 3,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.monitor_weight,
            title: 'Mesures',
            index: 4,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Paramètres Nutritionnels',
            index: 5,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.shopping_cart,
            title: 'Liste de courses',
            index: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        onItemSelected(index);
        Navigator.pop(context);
      },
    );
  }
} 
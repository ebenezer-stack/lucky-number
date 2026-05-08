import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/draw_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/statistics_bloc.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
    context.read<DrawBloc>().add(InitializeDraw());
    context.read<StatisticsBloc>().add(LoadStatistics());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          elevation: 0,
          backgroundColor: Theme.of(context).cardColor,
          indicatorColor: AppTheme.primaryColor.withAlpha(20),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: [
            _buildDestination(0, 'Tirage', Icons.casino_outlined, Icons.casino),
            _buildDestination(1, 'Historique', Icons.history_outlined, Icons.history),
            _buildDestination(2, 'Stats', Icons.bar_chart_outlined, Icons.bar_chart),
            _buildDestination(3, 'Profil', Icons.person_outline, Icons.person),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildDestination(int index, String label, IconData icon, IconData selectedIcon) {
    final isSelected = _currentIndex == index;
    return NavigationDestination(
      icon: Icon(icon, color: Colors.grey.shade500),
      selectedIcon: Icon(selectedIcon, color: AppTheme.primaryColor),
      label: label,
    );
  }
}


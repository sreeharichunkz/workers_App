import 'package:flutter/material.dart';
import 'dashboard_overview.dart';
import 'people_insights.dart';
import 'engagement_signals.dart';
import 'celebration_manager.dart';
import 'team_configuration.dart';

class DashboardShell extends StatefulWidget {
  final int currentIndex;
  const DashboardShell({super.key, this.currentIndex = 0});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _selectedIndex;

  final List<Widget> _screens = const [
    DashboardOverview(),
    PeopleInsightsScreen(),
    EngagementSignalsScreen(),
    CelebrationManagerScreen(),
    TeamConfigurationScreen(),
  ];

  final List<String> _titles = [
    'Dashboard Overview',
    'People Insights',
    'Engagement Signals',
    'Celebration Manager',
    'Team Configuration',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected:
                (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.indigo),
            selectedLabelTextStyle: const TextStyle(color: Colors.indigo),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('People'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.insights),
                label: Text('Signals'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cake),
                label: Text('Celebrate'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Teams'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_titles[_selectedIndex]),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              body: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

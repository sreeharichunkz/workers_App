import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'kudos_send_screen.dart';
import 'profile_screen.dart';
import 'team_feed_screen.dart';

class MainTabScreen extends StatefulWidget {
  final String name;
  final String uid;
  final String team;
  final String teamId;

  const MainTabScreen({
    super.key,
    required this.name,
    required this.uid,
    required this.team,
    required this.teamId,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        key: _homeKey,
        name: widget.name,
        team: widget.team,
        uid: widget.uid,
        teamId: widget.teamId,
      ),
      KudosSendScreen(
        uid: widget.uid,
        name: widget.name,
        teamId: widget.teamId,
      ),
      TeamFeedScreen(
        uid: widget.uid,
        teamId: widget.teamId,
        teamName: widget.team,
      ),
      ProfileScreen(uid: widget.uid, teamName: widget.team),
    ];
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Send Kudos';
      case 2:
        return 'Team';
      case 3:
        return 'Profile';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions:
            _selectedIndex == 0
                ? [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      _homeKey.currentState?.showRecentActivityModal();
                    },
                  ),
                ]
                : null,
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.thumb_up), label: "Kudos"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Team"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

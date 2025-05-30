import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'kudos_send_screen.dart';
import 'profile_screen.dart';

class MainTabScreen extends StatefulWidget {
  final String name;
  final String uid;
  final String team;

  const MainTabScreen({
    super.key,
    required this.name,
    required this.uid,
    required this.team,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(name: widget.name, team: widget.team, uid: widget.uid),
      KudosSendScreen(uid: widget.uid, name: widget.name), // ✅ pass here
      ProfileScreen(name: widget.name, team: widget.team),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) {
          setState(() => _selectedIndex = idx);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.thumb_up), label: "Kudos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

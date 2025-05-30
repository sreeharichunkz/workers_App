import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String team;

  const ProfileScreen({super.key, required this.name, required this.team});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Profile", style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Text("Name: $name", style: const TextStyle(fontSize: 18)),
          Text("Team: $team", style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

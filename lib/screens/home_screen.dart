// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String name;
  final String team;
  final String uid;

  const HomeScreen({
    super.key,
    required this.name,
    required this.team,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hi, $name!', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 12),
            Text('Team: $team', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/send-kudos',
                  arguments: {'uid': uid, 'name': name, 'team': team},
                );
              },
              child: const Text("Send Kudos"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/kudos-history');
              },
              child: const Text("Kudos History"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int teamKudos = 0;
  int activeUsers = 0;

  @override
  void initState() {
    super.initState();
    fetchManagerStats();
  }

  Future<void> fetchManagerStats() async {
    final kudosSnap =
        await FirebaseFirestore.instance.collection('kudos').get();
    final userSnap = await FirebaseFirestore.instance.collection('users').get();

    if (mounted) {
      setState(() {
        teamKudos = kudosSnap.size;
        activeUsers =
            userSnap.docs.where((u) => u['role'] == 'employee').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Manager 💼",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  title: "Team Kudos",
                  value: teamKudos.toString(),
                  icon: Icons.thumb_up_alt_outlined,
                ),
                _StatCard(
                  title: "Active Employees",
                  value: activeUsers.toString(),
                  icon: Icons.group_outlined,
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text("🧑‍💼 Top Contributors (Coming Soon)"),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text("Contribution chart placeholder"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}

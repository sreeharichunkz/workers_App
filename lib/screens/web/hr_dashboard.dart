import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  int userCount = 0;
  int kudosCount = 0;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    final kudosSnap =
        await FirebaseFirestore.instance.collection('kudos').get();

    if (mounted) {
      setState(() {
        userCount = usersSnap.size;
        kudosCount = kudosSnap.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HR Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome HR 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  title: "Total Users",
                  value: userCount.toString(),
                  icon: Icons.people,
                ),
                _StatCard(
                  title: "Total Kudos",
                  value: kudosCount.toString(),
                  icon: Icons.thumb_up_alt,
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text("📈 Mood Trends (Coming Soon)"),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text("Chart goes here")),
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

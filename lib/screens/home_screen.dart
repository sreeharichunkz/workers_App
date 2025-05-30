import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'kudos_send_screen.dart';
import 'mood_checkin_screen.dart';

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

  String getTodayDate() {
    return DateFormat('MMMM dd, yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Greeting
            Text(
              'Hi, $name 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Team: $team'),
            Text(
              'Today: ${getTodayDate()}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 🔥 Summary Cards
            const Text(
              "🔥 This Week's Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard('💬', 'Kudos', '12'),
                _buildSummaryCard('😊', 'Mood', '4.5'),
                _buildSummaryCard('🎂', 'Bdays', '2'),
              ],
            ),
            const SizedBox(height: 30),

            // 🚀 Quick Actions
            const Text(
              "🚀 Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => KudosSendScreen(uid: uid, name: name),
                      ),
                    );
                  },
                  icon: const Icon(Icons.thumb_up),
                  label: const Text("Send Kudos"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                MoodCheckinScreen(uid: uid, name: name),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_emotions),
                  label: const Text("Mood Check"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement icebreaker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Coming soon!")),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text("Icebreaker"),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 📢 Recent Team Activity
            const Text(
              "📢 Recent Team Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildActivityItem('Sreehari sent kudos to John'),
            _buildActivityItem('Anna checked in 😊'),
            _buildActivityItem('Raj answered the icebreaker'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String emoji, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications),
      title: Text(text),
    );
  }
}

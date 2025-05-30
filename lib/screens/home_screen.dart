import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'mood_checkin_screen.dart';
import 'kudos_send_screen.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int sentKudosCount = 0;
  int receivedKudosCount = 0;
  int moodCount = 0;
  int birthdayCount = 0;
  List<String> recentActivities = [];

  @override
  void initState() {
    super.initState();
    _subscribeToKudos();
    _fetchMoodCount();
    _fetchBirthdays();
    _fetchRecentActivities();
  }

  void _subscribeToKudos() {
    FirebaseFirestore.instance.collection('kudos').snapshots().listen((
      snapshot,
    ) {
      int sent = 0;
      int received = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['sender_uid'] == widget.uid) sent++;
        if (data['receiver_uid'] == widget.uid) received++;
      }

      if (mounted) {
        setState(() {
          sentKudosCount = sent;
          receivedKudosCount = received;
        });
      }
    });
  }

  void _fetchMoodCount() {
    FirebaseFirestore.instance
        .collection('mood_checkins')
        .where('uid', isEqualTo: widget.uid)
        .get()
        .then((snapshot) {
          setState(() {
            moodCount = snapshot.docs.length;
          });
        });
  }

  void _fetchBirthdays() {
    final today = DateTime.now();
    final thisMonth = today.month;

    FirebaseFirestore.instance.collection('users').get().then((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('birthday')) {
          final birthday = DateTime.parse(data['birthday']);
          if (birthday.month == thisMonth) {
            count++;
          }
        }
      }
      setState(() {
        birthdayCount = count;
      });
    });
  }

  void _fetchRecentActivities() {
    FirebaseFirestore.instance
        .collection('kudos')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
          List<String> activities = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data.containsKey('sender') && data.containsKey('receiver')) {
              activities.add(
                "${data['sender']} sent kudos to ${data['receiver']}",
              );
            }
          }

          setState(() {
            recentActivities = activities;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${widget.name} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Team: ${widget.team}'),
            Text('Today: $today'),
            const SizedBox(height: 20),
            const Text(
              '🔥 This Week\'s Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCard(
                  '💬 Kudos',
                  '${sentKudosCount + receivedKudosCount}',
                ),
                _summaryCard('😊 Mood', '$moodCount'),
                _summaryCard('🎂 Bdays', '$birthdayCount'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '🔔 Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => KudosSendScreen(
                              uid: widget.uid,
                              name: widget.name,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.thumb_up),
                  label: const Text('Send Kudos'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MoodCheckinScreen(
                              uid: widget.uid,
                              name: widget.name,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mood),
                  label: const Text('Mood Check'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon: Icebreaker!')),
                    );
                  },
                  icon: const Icon(Icons.question_answer),
                  label: const Text('Answer Icebreaker'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '📢 Recent Team Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...recentActivities.map(
              (activity) => ListTile(
                leading: const Icon(Icons.campaign),
                title: Text(activity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

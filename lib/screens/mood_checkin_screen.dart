import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodCheckinScreen extends StatefulWidget {
  final String uid;
  final String name;

  const MoodCheckinScreen({super.key, required this.uid, required this.name});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  int moodValue = 3;
  final TextEditingController _commentController = TextEditingController();

  final List<String> moods = ['😞', '😐', '🙂', '😃', '🤩'];

  Future<void> submitCheckin() async {
    final comment = _commentController.text.trim();
    final timestamp = Timestamp.now();

    final checkinData = {
      'uid': widget.uid,
      'name': widget.name,
      'mood': moodValue,
      'comment': comment,
      'timestamp': timestamp,
    };

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid);

    try {
      // 1. Submit to checkins collection (history)
      await FirebaseFirestore.instance.collection('checkins').add(checkinData);

      // 2. Get current latest mood timestamp
      final userDoc = await userRef.get();
      final currentMoodTimestamp =
          userDoc.data()?['latest_mood']?['timestamp'] as Timestamp? ??
          Timestamp(0, 0);

      // 3. Only update if new timestamp is more recent
      if (timestamp.compareTo(currentMoodTimestamp) > 0) {
        await userRef.update({
          'latest_mood': {
            'value': moodValue,
            'emoji': moods[moodValue - 1],
            'comment': comment,
            'timestamp': timestamp,
          },
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mood check-in submitted!')));

      _commentController.clear();
      setState(() => moodValue = 3);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit mood: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mood Check-in")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "How are you feeling today?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Emoji Slider
            Text(moods[moodValue - 1], style: const TextStyle(fontSize: 60)),
            Slider(
              value: moodValue.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: moodValue.toString(),
              onChanged: (val) {
                setState(() => moodValue = val.round());
              },
            ),
            const SizedBox(height: 20),

            // Comment Box
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: "Optional comment",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: submitCheckin,
              icon: const Icon(Icons.send),
              label: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

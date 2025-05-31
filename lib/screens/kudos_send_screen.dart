import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KudosSendScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String teamId;

  const KudosSendScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.teamId,
  });

  @override
  State<KudosSendScreen> createState() => _KudosSendScreenState();
}

class _KudosSendScreenState extends State<KudosSendScreen> {
  List<Map<String, dynamic>> teammates = [];
  String? selectedTeammate;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final users =
          querySnapshot.docs
              .where((doc) => doc.id != widget.uid)
              .map((doc) => {'uid': doc.id, 'name': doc['name']})
              .toList();

      debugPrint("👥 Filtered teammates: $users");

      if (mounted) {
        setState(() {
          teammates = users;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching users: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading teammates: $e")));
      }
    }
  }

  Future<void> sendKudos() async {
    if (selectedTeammate == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a teammate and enter a message"),
        ),
      );
      return;
    }

    final receiver = teammates.firstWhere((t) => t['uid'] == selectedTeammate);

    final receiverDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(selectedTeammate)
            .get();

    final receiverData = receiverDoc.data();
    final receiverTeamId = receiverData?['team_id'] ?? '';

    final kudosData = {
      'sender_uid': widget.uid,
      'receiver_uid': selectedTeammate,
      'sender': widget.name,
      'receiver': receiver['name'],
      'message': _messageController.text.trim(),
      'timestamp': Timestamp.now(),
      'receiver_team_id': receiverTeamId,
      'likes': [], // ✅ empty likes list
      'comments': [], // ✅ empty comments list
    };

    debugPrint("📬 Sending kudos: $kudosData");

    await FirebaseFirestore.instance.collection('kudos').add(kudosData);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Kudos sent!")));

    _messageController.clear();
    if (mounted) {
      setState(() => selectedTeammate = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Kudos")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedTeammate,
              decoration: const InputDecoration(labelText: "Select Teammate"),
              items:
                  teammates.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['uid'],
                      child: Text(user['name']),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => selectedTeammate = val),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Your message'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendKudos,
              child: const Text("Send Kudos"),
            ),
          ],
        ),
      ),
    );
  }
}

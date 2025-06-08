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
  final List<String> tagOptions = [
    'Collaborative',
    'Project Completion',
    'Best Presenter',
    'Problem Solver',
    'Team Player',
  ];
  final List<String> selectedTags = [];

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
    if (selectedTeammate == null ||
        _messageController.text.trim().isEmpty ||
        selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a teammate, enter a message, and choose at least one tag",
          ),
        ),
      );
      return;
    }

    final receiver = teammates.firstWhere((t) => t['uid'] == selectedTeammate);

    // ✅ Ensure receiver's team_id is fetched correctly
    final receiverDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(selectedTeammate)
            .get();
    final receiverData = receiverDoc.data();
    final receiverTeamId = receiverData?['team_id'] ?? '';

    // 🧠 Debug prints
    print('📤 Sending kudos to: ${receiver['name']}');
    print('🧾 Message: ${_messageController.text.trim()}');
    print('🏷️ Tags: $selectedTags');
    print('👥 Team ID: $receiverTeamId');

    final kudosData = {
      'sender_uid': widget.uid,
      'receiver_uid': selectedTeammate,
      'sender': widget.name,
      'receiver': receiver['name'],
      'message': _messageController.text.trim(),
      'timestamp': Timestamp.now(),
      'receiver_team_id': receiverTeamId,
      'likes': [],
      'comments': [],
      'tags': List<String>.from(selectedTags),
    };

    // ⚡️ Optimistic UI update
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Kudos sent!")));

    _messageController.clear();
    if (mounted) {
      setState(() {
        selectedTeammate = null;
        selectedTags.clear();
      });
    }

    try {
      await FirebaseFirestore.instance.collection('kudos').add(kudosData);
    } catch (e) {
      debugPrint("❌ Firestore write failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Kudos")),
      body: SingleChildScrollView(
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
            Wrap(
              spacing: 8,
              children:
                  tagOptions.map((tag) {
                    final selected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
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

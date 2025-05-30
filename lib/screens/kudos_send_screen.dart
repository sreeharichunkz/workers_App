import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KudosSendScreen extends StatefulWidget {
  const KudosSendScreen({super.key});

  @override
  State<KudosSendScreen> createState() => _KudosSendScreenState();
}

class _KudosSendScreenState extends State<KudosSendScreen> {
  List<Map<String, dynamic>> teammates = [];
  String? selectedTeammate;
  final TextEditingController _messageController = TextEditingController();

  String? senderUid;
  String? senderName;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void loadSenderInfo() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      senderUid = args['uid'];
      senderName = args['name'];
      debugPrint("Sender UID: $senderUid, Name: $senderName");
    } else {
      debugPrint("No sender info received from previous screen.");
    }
  }

  Future<void> fetchUsers() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final users =
        querySnapshot.docs
            .map((doc) => {'uid': doc['uid'], 'name': doc['name']})
            .toList();

    setState(() {
      teammates = users;
    });
  }

  Future<void> sendKudos() async {
    if (selectedTeammate == null || _messageController.text.isEmpty) {
      debugPrint("Missing fields: teammate or message");
      return;
    }

    if (senderUid == null || senderName == null) {
      debugPrint("Error: Missing sender UID or name");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sender not found")));
      return;
    }

    final receiver = teammates.firstWhere((t) => t['uid'] == selectedTeammate);

    final kudosData = {
      'sender_uid': senderUid,
      'receiver_uid': selectedTeammate,
      'sender': senderName,
      'receiver': receiver['name'],
      'message': _messageController.text.trim(),
      'timestamp': Timestamp.now(),
    };

    debugPrint("Sending kudos: $kudosData");

    await FirebaseFirestore.instance.collection('kudos').add(kudosData);

    debugPrint("Kudos sent successfully!");

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Kudos sent!")));

    _messageController.clear();
    setState(() => selectedTeammate = null);
  }

  @override
  Widget build(BuildContext context) {
    if (senderUid == null || senderName == null) {
      // load only once when build is first called
      loadSenderInfo();
    }

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
              onChanged: (val) {
                setState(() {
                  selectedTeammate = val;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Your message'),
              maxLines: 3,
              onChanged: (val) => debugPrint("Message changed: $val"),
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

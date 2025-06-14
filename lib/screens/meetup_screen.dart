import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_meetup_screen.dart';

class MeetupScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String teamId;

  const MeetupScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.teamId,
  });

  @override
  State<MeetupScreen> createState() => _MeetupScreenState();
}

class _MeetupScreenState extends State<MeetupScreen> {
  bool readyForMeetup = false;
  bool isLoadingToggle = true;

  @override
  void initState() {
    super.initState();
    _loadToggleStatus();
  }

  Future<void> _loadToggleStatus() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();

    setState(() {
      readyForMeetup =
          userDoc.data() != null &&
                  userDoc.data()!.containsKey('ready_for_meetup')
              ? userDoc['ready_for_meetup']
              : false;
      isLoadingToggle = false;
    });
  }

  Future<void> _toggleReady(bool value) async {
    setState(() {
      readyForMeetup = value;
      isLoadingToggle = true;
    });

    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update(
      {'ready_for_meetup': value},
    );

    setState(() => isLoadingToggle = false);
  }

  Future<void> _matchTwoUsers() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('ready_for_meetup', isEqualTo: true)
            .get();

    final users = snapshot.docs;
    if (users.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not enough users available for matching."),
        ),
      );
      return;
    }

    users.shuffle();
    final user1 = users[0];
    final user2 = users[1];

    // Write the match to Firestore
    await FirebaseFirestore.instance.collection('meetup_matches').add({
      'user1_id': user1.id,
      'user1_name': user1['name'],
      'user2_id': user2.id,
      'user2_name': user2['name'],
      'status': 'pending',
      'created_at': Timestamp.now(),
    });

    // Optionally: record last match timestamp, but DO NOT turn off their toggle
    final now = Timestamp.now();
    await FirebaseFirestore.instance.collection('users').doc(user1.id).update({
      'last_matched_at': now,
    });
    await FirebaseFirestore.instance.collection('users').doc(user2.id).update({
      'last_matched_at': now,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Matched ${user1['name']} with ${user2['name']}!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("☕ Lunch / Coffee Meetups")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CreateMeetupScreen(
                    uid: widget.uid,
                    name: widget.name,
                    teamId: widget.teamId,
                  ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          if (isLoadingToggle)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Column(
              children: [
                SwitchListTile(
                  title: const Text("I'm open to being matched for a meetup"),
                  value: readyForMeetup,
                  onChanged: _toggleReady,
                  secondary: const Icon(Icons.handshake),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shuffle),
                  label: const Text("Match Random Users"),
                  onPressed: _matchTwoUsers,
                ),
              ],
            ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('meetups')
                      .where('team_id', isEqualTo: widget.teamId)
                      .orderBy('datetime', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final now = DateTime.now();
                final docs = snapshot.data!.docs;

                final upcoming =
                    docs
                        .where(
                          (doc) => (doc['datetime'] as Timestamp)
                              .toDate()
                              .isAfter(now),
                        )
                        .toList();

                final past =
                    docs
                        .where(
                          (doc) => (doc['datetime'] as Timestamp)
                              .toDate()
                              .isBefore(now),
                        )
                        .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Upcoming Meetups",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.map((doc) => _meetupTile(doc)).toList(),
                    const SizedBox(height: 20),
                    const Text(
                      "Past Meetups",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...past.map((doc) => _meetupTile(doc)).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetupTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dateTime = (data['datetime'] as Timestamp).toDate();

    return ListTile(
      title: Text("${data['type']} Meetup"),
      subtitle: Text("${data['location']} • ${dateTime.toLocal()}"),
      leading: const Icon(Icons.coffee),
    );
  }
}

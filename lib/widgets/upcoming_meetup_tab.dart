// lib/widgets/upcoming_meetup_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/matched_meetup_screen.dart';

class UpcomingMeetupTab extends StatelessWidget {
  final String uid;
  final String name;
  final String teamId;

  const UpcomingMeetupTab({
    super.key,
    required this.uid,
    required this.name,
    required this.teamId,
  });

  Stream<List<QueryDocumentSnapshot>> _upcomingMeetups() {
    return FirebaseFirestore.instance
        .collection('meetups')
        .where('team_id', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dt = (data['datetime'] as Timestamp).toDate();
            final participants = List<String>.from(data['participants'] ?? []);
            return participants.contains(uid) && dt.isAfter(DateTime.now());
          }).toList();
        });
  }

  Future<List<Widget>> _combinedUpcomingMeetups(BuildContext context) async {
    final meetupDocs = await _upcomingMeetups().first;
    final matchSnapshot =
        await FirebaseFirestore.instance
            .collection('meetup_matches')
            .where('status', isEqualTo: 'confirmed')
            .get();

    final List<Widget> tiles =
        meetupDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dateTime = (data['datetime'] as Timestamp).toDate();
          final maxPeople = data['max_people'] ?? 2;
          final participants = List<String>.from(data['participants'] ?? []);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text("${data['type']} Meetup"),
              subtitle: Text(
                "${data['location']} • ${dateTime.toLocal()} (${participants.length}/$maxPeople)",
              ),
            ),
          );
        }).toList();

    for (final doc in matchSnapshot.docs) {
      final data = doc.data();
      final acceptedIndex = data['accepted_proposal_index'];
      if (acceptedIndex == null) continue;

      final proposal = (data['proposals'] as List)[acceptedIndex];
      final date = (proposal['proposed_time'] as Timestamp).toDate();
      if (date.isBefore(DateTime.now())) continue;

      final isInvolved = data['user1_id'] == uid || data['user2_id'] == uid;
      if (!isInvolved) continue;

      final partnerName =
          data['user1_id'] == uid ? data['user2_name'] : data['user1_name'];

      tiles.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.link, color: Colors.green, size: 32),
            title: Text(
              "Matched with $partnerName",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${proposal['location']} • ${date.toLocal()}"),
            trailing: ElevatedButton(
              child: const Text("View"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchedMeetupScreen(uid: uid),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
      future: _combinedUpcomingMeetups(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tiles = snapshot.data!;
        if (tiles.isEmpty) {
          return const Center(child: Text("No upcoming meetups."));
        }
        return ListView(children: tiles);
      },
    );
  }
}

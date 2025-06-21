// lib/widgets/past_meetup_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PastMeetupTab extends StatelessWidget {
  final String uid;
  final String teamId;

  const PastMeetupTab({super.key, required this.uid, required this.teamId});

  Stream<List<QueryDocumentSnapshot>> _pastMeetups() {
    return FirebaseFirestore.instance
        .collection('meetups')
        .where('team_id', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dt = (data['datetime'] as Timestamp).toDate();
            final participants = List<String>.from(data['participants'] ?? []);
            return dt.isBefore(DateTime.now()) && participants.contains(uid);
          }).toList();
        });
  }

  Widget _meetupTile(QueryDocumentSnapshot doc) {
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
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _pastMeetups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final pastDocs = snapshot.data!;
        if (pastDocs.isEmpty) {
          return const Center(child: Text("No past meetups."));
        }
        return ListView(children: pastDocs.map(_meetupTile).toList());
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/kudos_feed_card.dart';

class TeamFeedScreen extends StatelessWidget {
  final String uid;
  final String teamId;
  final String teamName;

  const TeamFeedScreen({
    super.key,
    required this.uid,
    required this.teamId,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('kudos')
              .where('receiver_team_id', isEqualTo: teamId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return KudosFeedCard(currentUid: uid, data: data, docId: doc.id);
          },
        );
      },
    );
  }
}

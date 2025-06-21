import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/matched_meetup_screen.dart';

Future<void> matchTwoUsers(
  BuildContext context,
  String uid,
  String name,
) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .where('ready_for_meetup', isEqualTo: true)
          .get();

  final candidates = snapshot.docs.where((doc) => doc.id != uid).toList();
  candidates.shuffle();

  DocumentSnapshot? matchedUser;
  for (final doc in candidates) {
    if (!await _hasActiveMatch(doc.id)) {
      matchedUser = doc;
      break;
    }
  }

  if (matchedUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No available users to match with right now."),
      ),
    );
    return;
  }

  if (await _hasActiveMatch(uid)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You are already in a match.")),
    );
    return;
  }

  // Create match with pending status and no proposals
  final matchDoc = await FirebaseFirestore.instance
      .collection('meetup_matches')
      .add({
        'user1_id': uid,
        'user1_name': name,
        'user2_id': matchedUser.id,
        'user2_name': matchedUser['name'],
        'status': 'pending', // Changed from 'confirmed' to 'pending'
        'created_at': Timestamp.now(),
        'accepted_proposal_index': null, // No accepted proposal initially
        'proposals': [], // Empty proposals array initially
      });

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'current_match_id': matchDoc.id,
    'last_matched_at': Timestamp.now(),
  });

  await FirebaseFirestore.instance
      .collection('users')
      .doc(matchedUser.id)
      .update({
        'current_match_id': matchDoc.id,
        'last_matched_at': Timestamp.now(),
      });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("You matched with ${matchedUser['name']}!")),
  );
}

Future<void> goToMatchedScreen(BuildContext context, String uid) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final matchId = userDoc.data()?['current_match_id'];

  if (matchId == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("No active match found.")));
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MatchedMeetupScreen(uid: uid)),
  );
}

Future<bool> _hasActiveMatch(String uid) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final matchId = userDoc.data()?['current_match_id'];

  if (matchId == null) return false;

  final matchDoc =
      await FirebaseFirestore.instance
          .collection('meetup_matches')
          .doc(matchId)
          .get();
  if (!matchDoc.exists) return false;

  final data = matchDoc.data()!;
  final createdAt = (data['created_at'] as Timestamp).toDate();
  return DateTime.now().difference(createdAt).inHours < 48;
}

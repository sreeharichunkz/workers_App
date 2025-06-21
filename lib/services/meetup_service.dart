// Firestore Models & Logic for Coffee Meetup Matching

import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Model: Meetup Status (tracks availability)
Future<void> updateMeetupAvailability(String uid, bool isAvailable) async {
  await _firestore.collection('meetup_status').doc(uid).set({
    'uid': uid,
    'isAvailable': isAvailable,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

// Check for active invites (sent or received)
Future<bool> hasActiveInvite(String uid) async {
  final snapshot =
      await _firestore
          .collection('meetup_invites')
          .where('status', isEqualTo: 'pending')
          .where('expires_at', isGreaterThan: Timestamp.now())
          .where(
            Filter.or(
              Filter("from_uid", isEqualTo: uid),
              Filter("to_uid", isEqualTo: uid),
            ),
          )
          .get();

  return snapshot.docs.isNotEmpty;
}

// Try to find another available user and create an invite
Future<bool> tryMatchRandomUser(String currentUid) async {
  if (await hasActiveInvite(currentUid)) return false;

  final availableUsers =
      await _firestore
          .collection('meetup_status')
          .where('isAvailable', isEqualTo: true)
          .orderBy('timestamp')
          .get();

  for (final doc in availableUsers.docs) {
    final otherUid = doc.id;
    if (otherUid == currentUid) continue;

    if (!(await hasActiveInvite(otherUid))) {
      // Create invite
      await _firestore.collection('meetup_invites').add({
        'from_uid': currentUid,
        'to_uid': otherUid,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(Duration(hours: 48)),
        ),
        'proposed_datetime': null,
        'location': null,
      });

      // Set both users as unavailable
      await updateMeetupAvailability(currentUid, false);
      await updateMeetupAvailability(otherUid, false);
      return true;
    }
  }
  return false;
}

// Accept or Reject Invite
Future<void> respondToInvite(String inviteId, String response) async {
  final doc = _firestore.collection('meetup_invites').doc(inviteId);
  await doc.update({'status': response});

  final snapshot = await doc.get();
  final data = snapshot.data();
  if (response == 'rejected') {
    await updateMeetupAvailability(data!['from_uid'], true);
    await updateMeetupAvailability(data['to_uid'], true);
  }
}

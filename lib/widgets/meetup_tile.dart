// lib/utils/meetup_actions.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cancelMeetup(
  BuildContext context,
  DocumentReference reference,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Cancel Meetup'),
          content: const Text('Are you sure you want to cancel this meetup?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
  );

  if (confirm == true) {
    await reference.delete();
  }
}

Future<void> leaveMeetup(
  BuildContext context,
  DateTime meetupTime,
  String uid,
  DocumentReference reference,
) async {
  if (meetupTime.difference(DateTime.now()).inMinutes < 60) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Can't leave within 1 hour of the meetup.")),
    );
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Leave Meetup'),
          content: const Text('Are you sure you want to leave this meetup?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
  );

  if (confirm == true) {
    await reference.update({
      'participants': FieldValue.arrayRemove([uid]),
    });
  }
}

Future<void> acceptMeetup(
  BuildContext context,
  List<String> participants,
  int maxPeople,
  String uid,
  DocumentReference reference,
) async {
  if (participants.contains(uid)) return;
  if (participants.length >= maxPeople) return;

  await reference.update({
    'participants': FieldValue.arrayUnion([uid]),
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('You have accepted the meetup!')),
  );
}

Widget meetupTile(
  QueryDocumentSnapshot doc,
  String currentUserId,
  BuildContext context,
) {
  final data = doc.data() as Map<String, dynamic>;
  final dateTime = (data['datetime'] as Timestamp).toDate();
  final maxPeople = data['max_people'] ?? 2;
  final participants = List<String>.from(data['participants'] ?? []);
  final isCreator = data['creator_uid'] == currentUserId;
  final joined = participants.contains(currentUserId);
  final isFull = participants.length >= maxPeople;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      title: Text("${data['type']} Meetup"),
      subtitle: Text(
        "${data['location']} • ${dateTime.toLocal()} (${participants.length}/$maxPeople)",
      ),
      trailing:
          isCreator
              ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => cancelMeetup(context, doc.reference),
              )
              : joined
              ? TextButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Leave"),
                onPressed:
                    () => leaveMeetup(
                      context,
                      dateTime,
                      currentUserId,
                      doc.reference,
                    ),
              )
              : isFull
              ? const Text("Full", style: TextStyle(color: Colors.red))
              : ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Accept"),
                onPressed:
                    () => acceptMeetup(
                      context,
                      participants,
                      maxPeople,
                      currentUserId,
                      doc.reference,
                    ),
              ),
    ),
  );
}

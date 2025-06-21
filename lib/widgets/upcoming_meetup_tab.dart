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

  Stream<List<Widget>> _combinedUpcomingMeetupsStream(
    BuildContext context,
  ) async* {
    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('meetups')
            .where('team_id', isEqualTo: teamId)
            .snapshots()) {
      final meetupDocs =
          snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dt = (data['datetime'] as Timestamp).toDate();
            final participants = List<String>.from(data['participants'] ?? []);
            return participants.contains(uid) && dt.isAfter(DateTime.now());
          }).toList();

      final matchSnapshot =
          await FirebaseFirestore.instance
              .collection('meetup_matches')
              .where('status', isEqualTo: 'confirmed')
              .get();

      final List<Widget> tiles = [];

      for (final doc in meetupDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateTime = (data['datetime'] as Timestamp).toDate();
        final maxPeople = data['max_people'] ?? 2;
        final participants = List<String>.from(data['participants'] ?? []);
        final isOrganizer = data['creator_uid'] == uid;

        tiles.add(
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text("${data['type']} Meetup"),
              subtitle: Text(
                "${data['location']} • ${dateTime.toLocal()} (${participants.length}/$maxPeople)",
              ),
              trailing: TextButton.icon(
                icon: Icon(
                  isOrganizer ? Icons.cancel : Icons.logout,
                  color: Colors.red,
                ),
                label: Text(isOrganizer ? "Cancel Meetup" : "Leave Meetup"),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: Text(
                            isOrganizer ? 'Cancel Meetup' : 'Leave Meetup',
                          ),
                          content: Text(
                            isOrganizer
                                ? 'Are you sure you want to cancel this meetup?'
                                : 'Do you want to leave this meetup?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Yes"),
                            ),
                          ],
                        ),
                  );

                  if (confirmed != true) return;

                  if (isOrganizer) {
                    await doc.reference.delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Meetup cancelled.")),
                    );
                  } else {
                    await doc.reference.update({
                      'participants': FieldValue.arrayRemove([uid]),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You left the meetup.")),
                    );
                  }
                },
              ),
            ),
          ),
        );
      }

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

      yield tiles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Widget>>(
      stream: _combinedUpcomingMeetupsStream(context),
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

// lib/widgets/propose_meetup_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/meetup_actions.dart';
import 'meetup_tile.dart';

class ProposeMeetupTab extends StatefulWidget {
  final String uid;
  final String name;
  final String teamId;

  const ProposeMeetupTab({
    super.key,
    required this.uid,
    required this.name,
    required this.teamId,
  });

  @override
  State<ProposeMeetupTab> createState() => _ProposeMeetupTabState();
}

class _ProposeMeetupTabState extends State<ProposeMeetupTab> {
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
      readyForMeetup = userDoc.data()?['ready_for_meetup'] ?? false;
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

  Stream<List<QueryDocumentSnapshot>> _proposedMeetupsFromOthers() {
    return FirebaseFirestore.instance
        .collection('meetups')
        .where('team_id', isEqualTo: widget.teamId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final participants = List<String>.from(
                  data['participants'] ?? [],
                );
                final maxPeople = data['max_people'] ?? 2;
                final dateTime = (data['datetime'] as Timestamp).toDate();

                return data['creator_uid'] != widget.uid &&
                    !participants.contains(widget.uid) &&
                    participants.length < maxPeople &&
                    dateTime.isAfter(DateTime.now());
              }).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onPressed:
                    () => matchTwoUsers(context, widget.uid, widget.name),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text("My Matched Meetup"),
                onPressed: () => goToMatchedScreen(context, widget.uid),
              ),
            ],
          ),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _proposedMeetupsFromOthers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final meetups = snapshot.data!;
              if (meetups.isEmpty) {
                return const Center(
                  child: Text("No meetups to join right now."),
                );
              }
              return ListView(
                children:
                    meetups
                        .map((doc) => meetupTile(doc, widget.uid, context))
                        .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

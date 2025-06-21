import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_meetup_screen.dart';
import 'matched_meetup_screen.dart';

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

class _MeetupScreenState extends State<MeetupScreen>
    with SingleTickerProviderStateMixin {
  bool readyForMeetup = false;
  bool isLoadingToggle = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  Future<void> _matchTwoUsers() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('ready_for_meetup', isEqualTo: true)
            .get();
    final candidates =
        snapshot.docs.where((doc) => doc.id != widget.uid).toList();
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

    if (await _hasActiveMatch(widget.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are already in a match.")),
      );
      return;
    }

    final matchDoc = await FirebaseFirestore.instance
        .collection('meetup_matches')
        .add({
          'user1_id': widget.uid,
          'user1_name': widget.name,
          'user2_id': matchedUser.id,
          'user2_name': matchedUser['name'],
          'status': 'pending',
          'created_at': Timestamp.now(),
        });

    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update(
      {'current_match_id': matchDoc.id, 'last_matched_at': Timestamp.now()},
    );

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

  Future<void> _goToMatchedScreen() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();
    final matchId = userDoc.data()?['current_match_id'];
    if (matchId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No active match found.")));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MatchedMeetupScreen(uid: widget.uid)),
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

  Widget _buildMeetupList({required List<QueryDocumentSnapshot> docs}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) => _meetupTile(docs[index]),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _proposedMeetupsFromOthers() {
    return FirebaseFirestore.instance
        .collection('meetups')
        .where('team_id', isEqualTo: widget.teamId)
        .where('creator_uid', isNotEqualTo: widget.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot>> _confirmedMeetups() {
    return FirebaseFirestore.instance
        .collection('meetup_matches')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final acceptedIndex = data['accepted_proposal_index'];
                return acceptedIndex != null;
              }).toList(),
        );
  }

  Stream<List<QueryDocumentSnapshot>> _pastMeetups() {
    return FirebaseFirestore.instance
        .collection('meetups')
        .where('team_id', isEqualTo: widget.teamId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .where(
                    (doc) => (doc['datetime'] as Timestamp).toDate().isBefore(
                      DateTime.now(),
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("☕ Lunch / Coffee Meetups"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Propose"),
            Tab(text: "Upcoming"),
            Tab(text: "Past"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => CreateMeetupScreen(
                      uid: widget.uid,
                      name: widget.name,
                      teamId: widget.teamId,
                    ),
              ),
            ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
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
                      title: const Text(
                        "I'm open to being matched for a meetup",
                      ),
                      value: readyForMeetup,
                      onChanged: _toggleReady,
                      secondary: const Icon(Icons.handshake),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shuffle),
                      label: const Text("Match Random Users"),
                      onPressed: _matchTwoUsers,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person),
                      label: const Text("My Matched Meetup"),
                      onPressed: _goToMatchedScreen,
                    ),
                  ],
                ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: _proposedMeetupsFromOthers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    return _buildMeetupList(docs: snapshot.data!);
                  },
                ),
              ),
            ],
          ),
          StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _confirmedMeetups(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text('Error: \${snapshot.error}'));
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final proposal =
                      (data['proposals']
                          as List)[data['accepted_proposal_index']];
                  final location = proposal['location'];
                  final timestamp =
                      (proposal['proposed_time'] as Timestamp).toDate();

                  return ListTile(
                    title: const Text("Confirmed Meetup"),
                    subtitle: Text("$location • ${timestamp.toLocal()}"),
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  );
                },
              );
            },
          ),
          StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _pastMeetups(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return _buildMeetupList(docs: snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

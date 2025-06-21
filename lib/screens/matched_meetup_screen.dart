import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class MatchedMeetupScreen extends StatefulWidget {
  final String uid;

  const MatchedMeetupScreen({super.key, required this.uid});

  @override
  State<MatchedMeetupScreen> createState() => _MatchedMeetupScreenState();
}

class _MatchedMeetupScreenState extends State<MatchedMeetupScreen> {
  DocumentSnapshot? matchDoc;
  bool isLoading = true;
  bool showRescheduleForm = false;
  final locationController = TextEditingController();
  final messageController = TextEditingController();
  DateTime? selectedDateTime;
  Timer? countdownTimer;
  Duration? timeRemaining;
  StreamSubscription<DocumentSnapshot>? matchSub;

  @override
  void initState() {
    super.initState();
    _listenToMatch();
  }

  void _listenToMatch() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();
    final matchId = userDoc.data()?['current_match_id'];
    if (matchId == null) {
      setState(() {
        isLoading = false;
        matchDoc = null;
      });
      return;
    }

    matchSub = FirebaseFirestore.instance
        .collection('meetup_matches')
        .doc(matchId)
        .snapshots()
        .listen((snapshot) {
          final createdAt =
              (snapshot.data()?['created_at'] as Timestamp).toDate();
          final now = DateTime.now();

          final status = snapshot.data()?['status'];

          if (now.difference(createdAt).inHours > 48) {
            setState(() {
              matchDoc = null;
              isLoading = false;
            });
            return;
          }

          if (status != 'confirmed') {
            timeRemaining = Duration(hours: 48) - now.difference(createdAt);
            countdownTimer?.cancel();
            countdownTimer = Timer.periodic(
              const Duration(seconds: 1),
              (_) => setState(
                () =>
                    timeRemaining = timeRemaining! - const Duration(seconds: 1),
              ),
            );
          }

          setState(() {
            matchDoc = snapshot;
            isLoading = false;
          });
        });
  }

  Future<void> _proposeMeetup() async {
    if (locationController.text.isEmpty || selectedDateTime == null) return;

    final existingProposals =
        (matchDoc!.data() as Map<String, dynamic>)['proposals'] ?? [];
    final newProposal = {
      'proposed_by': widget.uid,
      'proposed_time': selectedDateTime,
      'location': locationController.text,
      'message': messageController.text,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    };

    await matchDoc!.reference.update({
      'status': 'proposed',
      'proposals': [...existingProposals, newProposal],
      'accepted_proposal_index': null,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Proposal sent!")));

    setState(() {
      showRescheduleForm = false;
      locationController.clear();
      messageController.clear();
      selectedDateTime = null;
    });
  }

  Future<void> _acceptMatch() async =>
      await matchDoc!.reference.update({'status': 'awaiting_proposal'});
  Future<void> _rejectMatch() async => _cancelMatch();

  Future<void> _acceptProposal(int index) async {
    final currentProposals = List<Map<String, dynamic>>.from(
      (matchDoc!.data() as Map<String, dynamic>)['proposals'],
    );
    final updatedProposals =
        currentProposals
            .asMap()
            .entries
            .map(
              (e) => {
                ...e.value,
                'status': e.key == index ? 'accepted' : 'rejected',
              },
            )
            .toList();

    await matchDoc!.reference.update({
      'status': 'confirmed',
      'accepted_proposal_index': index,
      'proposals': updatedProposals,
    });
  }

  Future<void> _rejectProposal(int index) async {
    final currentProposals = List<Map<String, dynamic>>.from(
      (matchDoc!.data() as Map<String, dynamic>)['proposals'],
    );
    currentProposals[index]['status'] = 'rejected';
    await matchDoc!.reference.update({'proposals': currentProposals});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Proposal rejected.")));
  }

  Future<void> _cancelMatch() async {
    final data = matchDoc!.data() as Map<String, dynamic>;
    final user1Id = data['user1_id'];
    final user2Id = data['user2_id'];

    await matchDoc!.reference.delete();
    await FirebaseFirestore.instance.collection('users').doc(user1Id).update({
      'current_match_id': FieldValue.delete(),
    });
    await FirebaseFirestore.instance.collection('users').doc(user2Id).update({
      'current_match_id': FieldValue.delete(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Match cancelled.")));

    setState(() => matchDoc = null);
  }

  String _formatDuration(Duration d) =>
      '${d.inHours} h ${d.inMinutes % 60} m ${d.inSeconds % 60} s left';

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.shade200;
      case 'rejected':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildRescheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: locationController,
          decoration: const InputDecoration(labelText: 'Location'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (date == null) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time == null) return;
            setState(
              () =>
                  selectedDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
            );
          },
          child: Text(
            selectedDateTime == null
                ? "Pick Date & Time"
                : DateFormat.yMd().add_jm().format(selectedDateTime!),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: messageController,
          decoration: const InputDecoration(labelText: 'Message / Reason'),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text("Submit"),
          onPressed: _proposeMeetup,
        ),
      ],
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    matchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (matchDoc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Matched Meetup")),
        body: const Center(
          child: Text("You have no current match or it expired."),
        ),
      );
    }

    final data = matchDoc!.data() as Map<String, dynamic>;
    final isUser1 = data['user1_id'] == widget.uid;
    final partnerName = isUser1 ? data['user2_name'] : data['user1_name'];
    final status = data['status'];
    final hasAccepted = status != 'pending';
    final proposals = List<Map<String, dynamic>>.from(data['proposals'] ?? []);
    final acceptedIndex = data['accepted_proposal_index'];

    return Scaffold(
      appBar: AppBar(title: const Text("Your Matched Meetup")),
      floatingActionButton:
          status == 'confirmed'
              ? FloatingActionButton.extended(
                onPressed: () => setState(() => showRescheduleForm = true),
                icon: const Icon(Icons.edit_calendar),
                label: const Text("Reschedule"),
              )
              : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You're matched with $partnerName",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (timeRemaining != null && status != 'confirmed')
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "⏳ ${_formatDuration(timeRemaining!)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (status == 'pending' && !isUser1) ...[
                const Text(
                  "This user has matched with you. Accept to start conversation.",
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Accept"),
                      onPressed: _acceptMatch,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text("Reject"),
                      onPressed: _rejectMatch,
                    ),
                  ],
                ),
              ],
              if (status == 'confirmed' && acceptedIndex != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Meetup confirmed at ${proposals[acceptedIndex]['location']} on ${DateFormat.yMd().add_jm().format((proposals[acceptedIndex]['proposed_time'] as Timestamp).toDate())}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              if ((hasAccepted && status != 'confirmed') ||
                  showRescheduleForm) ...[
                const Divider(),
                ExpansionTile(
                  title: const Text("📅 Propose / Reschedule Meetup"),
                  initiallyExpanded: showRescheduleForm,
                  onExpansionChanged:
                      (val) => setState(() => showRescheduleForm = val),
                  children: [_buildRescheduleForm()],
                ),
              ],
              if (proposals.isNotEmpty) ...[
                const Divider(),
                const Text("Proposals"),
                ...proposals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final p = entry.value;
                  final time = (p['proposed_time'] as Timestamp).toDate();
                  final accepted = acceptedIndex == index;
                  final byCurrentUser = p['proposed_by'] == widget.uid;
                  final status = p['status'];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.place),
                      title: Text(
                        "${p['location']} • ${DateFormat.yMd().add_jm().format(time)}",
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['message'] ?? ''),
                          Chip(
                            label: Text("Status: $status"),
                            backgroundColor: _statusColor(status),
                          ),
                        ],
                      ),
                      trailing:
                          accepted
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : (!byCurrentUser &&
                                  hasAccepted &&
                                  status == 'pending')
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _acceptProposal(index),
                                    child: const Text("Accept"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _rejectProposal(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text("Reject"),
                                  ),
                                ],
                              )
                              : null,
                    ),
                  );
                }),
              ],
              const SizedBox(height: 30),
              TextButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel Match"),
                onPressed: _cancelMatch,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/meetup_screen.dart

import 'package:flutter/material.dart';
import '../widgets/propose_meetup_tab.dart';
import '../widgets/upcoming_meetup_tab.dart';
import '../widgets/past_meetup_tab.dart';
import 'create_meetup_screen.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("☕ Meetups"),
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
          ProposeMeetupTab(
            uid: widget.uid,
            name: widget.name,
            teamId: widget.teamId,
          ),
          UpcomingMeetupTab(
            uid: widget.uid,
            name: widget.name,
            teamId: widget.teamId,
          ),
          PastMeetupTab(uid: widget.uid, teamId: widget.teamId),
        ],
      ),
    );
  }
}

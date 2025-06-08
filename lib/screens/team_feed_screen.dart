import 'package:flutter/material.dart';
import 'leadership_screen.dart'; // import this
import 'team_feed_activity_screen.dart'; // rename your current TeamFeedScreen to this internally

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Team Feed – $teamName'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Activity'), Tab(text: 'Leadership')],
          ),
        ),
        body: TabBarView(
          children: [
            TeamFeedActivityScreen(
              uid: uid,
              teamId: teamId,
              teamName: teamName,
            ),
            LeadershipScreen(teamId: teamId),
          ],
        ),
      ),
    );
  }
}

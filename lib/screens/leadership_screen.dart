import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeadershipScreen extends StatefulWidget {
  final String teamId;

  const LeadershipScreen({super.key, required this.teamId});

  @override
  State<LeadershipScreen> createState() => _LeadershipScreenState();
}

class _LeadershipScreenState extends State<LeadershipScreen> {
  late Future<Map<String, List<UserTagScore>>> _leaderboardFuture;
  String _selectedRange = 'All Time';

  final List<String> _timeRanges = ['All Time', 'Last 7 Days', 'This Month'];

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = fetchLeaderboard();
  }

  DateTime? getStartTime() {
    final now = DateTime.now();
    if (_selectedRange == 'Last 7 Days') {
      return now.subtract(const Duration(days: 7));
    } else if (_selectedRange == 'This Month') {
      return DateTime(now.year, now.month);
    }
    return null; // All time
  }

  Future<Map<String, List<UserTagScore>>> fetchLeaderboard() async {
    final startTime = getStartTime();

    Query query = FirebaseFirestore.instance
        .collection('kudos')
        .where('receiver_team_id', isEqualTo: widget.teamId);

    if (startTime != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
      );
    }

    final snapshot = await query.get();

    final Map<String, Map<String, UserTagScore>> tagMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final rawTags = data['tags'];
      final uid = data['receiver_uid'];
      final name = data['receiver'];

      if (rawTags == null || uid == null || name == null) continue;

      final tags = List<String>.from(rawTags);

      for (final tag in tags) {
        tagMap.putIfAbsent(tag, () => {});
        final userMap = tagMap[tag]!;

        userMap.update(
          uid,
          (existing) => existing.increment(),
          ifAbsent: () => UserTagScore(uid: uid, name: name, count: 1),
        );
      }
    }

    return {
      for (final entry in tagMap.entries)
        entry.key:
            entry.value.values.toList()
              ..sort((a, b) => b.count.compareTo(a.count)),
    };
  }

  void _onRangeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedRange = value;
      _leaderboardFuture = fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("Filter: "),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedRange,
                items:
                    _timeRanges
                        .map(
                          (range) => DropdownMenuItem<String>(
                            value: range,
                            child: Text(range),
                          ),
                        )
                        .toList(),
                onChanged: _onRangeChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, List<UserTagScore>>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No leadership data available.'),
                );
              }

              final leaderboard = snapshot.data!;

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children:
                    leaderboard.entries.map((entry) {
                      final tag = entry.key;
                      final users = entry.value;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Colors.grey.withOpacity(0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏷️ $tag',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ...users.asMap().entries.map((entry) {
                                final index = entry.key;
                                final user = entry.value;
                                final medal = ['🥇', '🥈', '🥉'];
                                final rankIcon =
                                    index < 3 ? medal[index] : "🔹";

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        index == 0
                                            ? Colors.amber.shade100
                                            : index == 1
                                            ? Colors.grey.shade200
                                            : index == 2
                                            ? Colors.brown.shade100
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          index == 0
                                              ? Colors.amber
                                              : Colors.indigo[100],
                                      child: Text(
                                        user.name.isNotEmpty
                                            ? user.name[0]
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    title: Text('$rankIcon ${user.name}'),
                                    trailing: Text(
                                      '${user.count}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class UserTagScore {
  final String uid;
  final String name;
  int count;

  UserTagScore({required this.uid, required this.name, required this.count});

  UserTagScore increment() {
    count += 1;
    return this;
  }
}

extension IterableExtensions<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    int index = 0;
    return map((e) => f(index++, e));
  }
}

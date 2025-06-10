import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);

    try {
      final kudosSnapshot =
          await FirebaseFirestore.instance.collection('kudos').get();
      final checkinsSnapshot =
          await FirebaseFirestore.instance.collection('checkins').get();

      final now = DateTime.now();

      final sentKudos = kudosSnapshot.docs.length;
      final receivedKudos =
          kudosSnapshot.docs
              .where((doc) => doc.data().containsKey('receiver_uid'))
              .length;

      final moodCheckinsToday =
          checkinsSnapshot.docs.where((doc) {
            final data = doc.data();
            if (!data.containsKey('timestamp')) return false;
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            return timestamp.year == now.year &&
                timestamp.month == now.month &&
                timestamp.day == now.day;
          }).length;

      setState(() {
        _stats = {
          'sentKudos': sentKudos,
          'receivedKudos': receivedKudos,
          'moodCheckinsToday': moodCheckinsToday,
        };
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_loading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard("🙌 Kudos Sent", _stats!['sentKudos'].toString()),
            _buildStatCard(
              "🎯 Kudos Received",
              _stats!['receivedKudos'].toString(),
            ),
            _buildStatCard(
              "😀 Mood Check-ins Today",
              _stats!['moodCheckinsToday'].toString(),
            ),
            _buildStatCard("📈 Active Users (WIP)", "—"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return SizedBox(
      width: 250,
      height: 140,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

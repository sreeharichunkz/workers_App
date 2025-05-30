import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class KudosHistoryScreen extends StatefulWidget {
  const KudosHistoryScreen({super.key});

  @override
  State<KudosHistoryScreen> createState() => _KudosHistoryScreenState();
}

class _KudosHistoryScreenState extends State<KudosHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? currentUid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (currentUid == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      currentUid = args?['uid'] ?? FirebaseAuth.instance.currentUser?.uid;

      // ✅ Print UID for debug
      debugPrint('📦 Received UID in KudosHistoryScreen: $currentUid');
    }
  }

  Stream<QuerySnapshot> _getSentKudos() {
    return FirebaseFirestore.instance
        .collection('kudos')
        .where('sender_uid', isEqualTo: currentUid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getReceivedKudos() {
    return FirebaseFirestore.instance
        .collection('kudos')
        .where('receiver_uid', isEqualTo: currentUid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Widget _buildKudosList(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No kudos found."));
        }

        return ListView(
          children:
              snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final from = data['sender'] ?? 'Unknown';
                final to = data['receiver'] ?? 'Unknown';
                final msg = data['message'] ?? '';
                final ts = (data['timestamp'] as Timestamp?)?.toDate();

                return ListTile(
                  title: Text('From: $from → To: $to'),
                  subtitle: Text(msg),
                  trailing: Text(
                    ts != null
                        ? "${ts.day}/${ts.month} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}"
                        : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kudos History"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Sent"), Tab(text: "Received")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKudosList(_getSentKudos()),
          _buildKudosList(_getReceivedKudos()),
        ],
      ),
    );
  }
}

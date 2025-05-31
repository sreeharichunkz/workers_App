import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String teamName;

  const ProfileScreen({super.key, required this.uid, required this.teamName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String team = '';
  String email = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();

      final data = doc.data();
      if (data != null) {
        setState(() {
          name = data['name'] ?? '';
          team = data['team'] ?? '';
          email = data['email'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch profile: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile_placeholder.png'),
                backgroundColor: Colors.indigo,
              ),
              const SizedBox(height: 20),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Team: $team",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Team Info'),
                  subtitle: Text(team),
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

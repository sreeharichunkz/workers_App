import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hr_dashboard.dart';
import 'manager_dashboard.dart';

class PortalEntryWrapper extends StatefulWidget {
  const PortalEntryWrapper({super.key});

  @override
  State<PortalEntryWrapper> createState() => _PortalEntryWrapperState();
}

class _PortalEntryWrapperState extends State<PortalEntryWrapper> {
  late Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = fetchUserRole();
  }

  Future<String?> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      return data?['role']; // 🚨 Make sure 'role' field exists: e.g., 'hr', 'manager'
    } catch (e) {
      debugPrint("❌ Error fetching user role: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("❌ Unable to verify access.")),
          );
        }

        final role = snapshot.data;
        switch (role) {
          case 'hr':
            return const HRDashboard();
          case 'manager':
            return const ManagerDashboard();
          default:
            return const Scaffold(
              body: Center(
                child: Text("🚫 Access denied. No portal role found."),
              ),
            );
        }
      },
    );
  }
}

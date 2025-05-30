import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String team;

  const ProfileScreen({super.key, required this.name, required this.team});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? photoUrl;
  bool isLoading = false;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      photoUrl = doc.data()?['photoUrl'];
    });
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || uid == null) return;

    setState(() => isLoading = true);

    final file = File(pickedFile.path);
    final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'photoUrl': downloadUrl,
    });

    setState(() {
      photoUrl = downloadUrl;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Profile", style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    photoUrl != null
                        ? NetworkImage(photoUrl!)
                        : const AssetImage('assets/profile_placeholder.jpg')
                            as ImageProvider,
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: _uploadProfilePhoto,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text("Name: ${widget.name}", style: const TextStyle(fontSize: 18)),
          Text("Team: ${widget.team}", style: const TextStyle(fontSize: 18)),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

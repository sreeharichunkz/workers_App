import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';
import 'screens/web/web_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA9-eZ2DZHQuKdjSqyf6QhRiYRQEZ0LLVg",
        authDomain: "workers-app-9548e.firebaseapp.com",
        projectId: "workers-app-9548e",
        storageBucket: "workers-app-9548e.appspot.com",
        messagingSenderId: "545024473042",
        appId: "1:545024473042:web:aa5c2af894c2d52480fa0b",
        measurementId: "G-28ZDELR4RV",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const WorkersApp());
}

class WorkersApp extends StatelessWidget {
  const WorkersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workers App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: kIsWeb ? const WebLoginScreen() : const WelcomeScreen(),
    );
  }
}

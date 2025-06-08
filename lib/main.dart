import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';
import 'screens/web/portal_entry_wrapper.dart'; // 🆕 Web entry point

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home:
          kIsWeb
              ? const PortalEntryWrapper() // 🖥️ Web version
              : const WelcomeScreen(), // 📱 Mobile version
    );
  }
}

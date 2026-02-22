import 'package:firebase_core/firebase_core.dart';
import 'package:blab_chat/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// here we used async and await and initialized firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

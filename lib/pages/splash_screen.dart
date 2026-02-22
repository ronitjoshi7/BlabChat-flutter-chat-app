import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _splashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(_splashDuration);

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 197, 67, 67),
      body: SizedBox.expand(
        child: Center(
          child: Text(
            'BlabChat.',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:e_commerce_2/features/signup_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final splashCompletedProvider = StateProvider<bool>((ref) => false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      ref.read(splashCompletedProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.chat_bubble_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Messenger',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fast • Secure • Simple',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashDone = ref.watch(splashCompletedProvider);

    if (!splashDone) {
      return const SplashScreen();
    }

    return const SignUpScreen(); // or AuthGate later
  }
}

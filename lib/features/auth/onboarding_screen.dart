import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamed('/login');
  }

  void _onGetStarted() {
    debugPrint('Get Started pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 72),
            const SizedBox(height: 24),
            const Text(
              'SquadHub',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your squad’s all-in-one toolkit',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onGetStarted,
                child: const Text('Get Started'),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _navigateToLogin(context),
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

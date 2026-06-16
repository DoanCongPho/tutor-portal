import 'package:flutter/material.dart';

/// Brief splash shown while we check whether the signed-in tutor has onboarded
/// (GET /tutors/me). The router redirects away from here as soon as the
/// [TutorGate] resolves to the wizard or the dashboard.
class TutorLoadingScreen extends StatelessWidget {
  const TutorLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

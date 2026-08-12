import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cabin_rounded, size: 60, color: AppTheme.forest),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

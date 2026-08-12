import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/presentation/app_shell.dart';
import 'features/shell/presentation/splash_screen.dart';

class CabinRentApp extends StatelessWidget {
  const CabinRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CabinRent Desktop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthController>(
        builder: (context, auth, _) => switch (auth.status) {
          AuthStatus.initial || AuthStatus.loading => const SplashScreen(),
          AuthStatus.authenticated => const AppShell(),
          AuthStatus.unauthenticated => const LoginScreen(),
        },
      ),
    );
  }
}

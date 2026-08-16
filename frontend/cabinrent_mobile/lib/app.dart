import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';

class CabinRentMobileApp extends StatelessWidget {
  const CabinRentMobileApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CabinRent',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Consumer<AuthController>(
      builder: (_, auth, _) => switch (auth.status) {
        AuthStatus.initial || AuthStatus.loading when auth.user == null =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        AuthStatus.authenticated => const HomeShell(),
        _ => const LoginScreen(),
      },
    ),
  );
}

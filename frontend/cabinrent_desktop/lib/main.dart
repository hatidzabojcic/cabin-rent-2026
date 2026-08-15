import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/cabins/data/cabins_repository.dart';
import 'features/reservations/data/reservations_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final tokenStorage = TokenStorage();
  final authRepository = AuthRepository(apiClient, tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: CabinsRepository(apiClient)),
        Provider.value(value: ReservationsRepository(apiClient)),
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository)..restoreSession(),
        ),
      ],
      child: const CabinRentApp(),
    ),
  );
}

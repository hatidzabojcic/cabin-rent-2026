import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/cabins/data/cabins_repository.dart';
import 'features/reservations/data/reservations_repository.dart';
import 'features/reviews/data/reviews_repository.dart';
import 'features/reports/data/reports_repository.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/notifications/presentation/notifications_controller.dart';
import 'features/users/data/users_repository.dart';
import 'features/catalog/data/reference_data_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final tokenStorage = TokenStorage();
  final authRepository = AuthRepository(apiClient, tokenStorage);
  final notificationsRepository = NotificationsRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: CabinsRepository(apiClient)),
        Provider.value(value: ReservationsRepository(apiClient)),
        Provider.value(value: ReviewsRepository(apiClient)),
        Provider.value(value: ReportsRepository(apiClient)),
        Provider.value(value: notificationsRepository),
        ChangeNotifierProvider(
          create: (_) => NotificationsController(notificationsRepository),
        ),
        Provider.value(value: UsersRepository(apiClient)),
        Provider.value(value: ReferenceDataRepository(apiClient)),
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository)..restoreSession(),
        ),
      ],
      child: const CabinRentApp(),
    ),
  );
}

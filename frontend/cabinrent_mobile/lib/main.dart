import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/cabins/data/cabins_repository.dart';
import 'features/cabins/presentation/cabins_controller.dart';
import 'features/favorites/data/favorites_repository.dart';
import 'features/favorites/presentation/favorites_controller.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/notifications/presentation/notifications_controller.dart';
import 'features/recommendations/data/recommendations_repository.dart';
import 'features/recommendations/presentation/recommendations_controller.dart';
import 'features/reservations/data/reservations_repository.dart';
import 'features/reservations/presentation/reservations_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthController(AuthRepository(api, const SessionStorage()))
                ..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => CabinsController(CabinsRepository(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesController(FavoritesRepository(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => ReservationsController(ReservationsRepository(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsController(NotificationsRepository(api)),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              RecommendationsController(RecommendationsRepository(api)),
        ),
      ],
      child: const CabinRentMobileApp(),
    ),
  );
}

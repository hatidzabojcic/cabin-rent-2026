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
import 'features/payments/data/payments_repository.dart';
import 'features/payments/presentation/payments_controller.dart';
import 'features/recommendations/data/recommendations_repository.dart';
import 'features/recommendations/presentation/recommendations_controller.dart';
import 'features/reservations/data/reservations_repository.dart';
import 'features/reservations/presentation/reservations_controller.dart';
import 'features/reviews/data/reviews_repository.dart';
import 'features/reviews/presentation/reviews_controller.dart';
import 'features/announcements/data/announcements_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final authRepository = AuthRepository(api, const SessionStorage());
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: authRepository),
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository)..restoreSession(),
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
          create: (_) => ReviewsController(ReviewsRepository(api)),
        ),
        Provider.value(value: AnnouncementsRepository(api)),
        ChangeNotifierProvider(
          create: (_) => NotificationsController(NotificationsRepository(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentsController(PaymentsRepository(api)),
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

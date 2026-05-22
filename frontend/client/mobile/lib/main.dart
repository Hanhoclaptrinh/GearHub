import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/notifications/push_notification_service.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await getIt<PushNotificationService>().initialize();

  runApp(const GearHubApp());
}

class GearHubApp extends StatelessWidget {
  const GearHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider<CartCubit>(create: (_) => getIt<CartCubit>()..loadCart()),
        BlocProvider<WishlistCubit>(
          create: (_) => getIt<WishlistCubit>()..fetchWishlist(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: PushNotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'GearHub',
        theme: AppTheme.theme(context),
        home: BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (prev, curr) =>
              curr is AuthAuthenticated ||
              curr is AuthUnauthenticated ||
              curr is AuthInitial,
          builder: (context, state) {
            return const MainScreen();
          },
        ),
      ),
    );
  }
}

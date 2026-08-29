import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'constants/app_theme.dart';
import 'providers/firebase_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/main_screen.dart';
import 'screens/edit_account_screen.dart';
import 'screens/shop_screen.dart';

// so ShopScreen can tell when we've come back to it (e.g. after checkout)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  // needed before we touch any plugins
  WidgetsFlutterBinding.ensureInitialized();

  // set up firebase before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MediBuddyApp()));
}

class MediBuddyApp extends ConsumerWidget {
  const MediBuddyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // login state + whatever theme colour the user picked
    final authState = ref.watch(authStateProvider);
    final themeColor = ref.watch(themeProvider);

    return MaterialApp(
      title: 'MediBuddy',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: AppTheme.buildTheme(themeColor),
      home: authState.when(
        data: (user) => user != null ? const MainScreen() : LoginScreen(),
        loading: () => Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: themeColor),
                const SizedBox(height: 16),
                Text(
                  'MediBuddy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Something went wrong: $err')),
        ),
      ),
      routes: {
        LoginScreen.routeName: (_) => LoginScreen(),
        SignupScreen.routeName: (_) => SignupScreen(),
        ResetPasswordScreen.routeName: (_) => ResetPasswordScreen(),
        MainScreen.routeName: (_) => const MainScreen(),
        EditAccountScreen.routeName: (_) => const EditAccountScreen(),
        ShopScreen.routeName: (_) => const ShopScreen(),
      },
    );
  }
}

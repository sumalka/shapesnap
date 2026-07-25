import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'viewmodels/app_state.dart';
import 'views/splash_screen.dart';
import 'views/signin_screen.dart';
import 'views/home_screen.dart';
import 'views/camera_screen.dart';
import 'views/occasion_screen.dart';
import 'views/profile_screen.dart';
import 'views/history_screen.dart';
import 'views/history_detail_screen.dart';
import 'views/onboarding_screen.dart';
import 'models/history_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Android/iOS
  await Firebase.initializeApp();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register HistoryEntry adapter
  Hive.registerAdapter(HistoryEntryAdapter());

  // Delete existing box if it exists with wrong type
  try {
    await Hive.deleteBoxFromDisk('history');
    print('🗑️ Deleted existing history box');
  } catch (e) {
    print('No existing box to delete');
  }

  // Open the box with the correct type
  await Hive.openBox<HistoryEntry>('history');

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const ShapeSnapApp(),
    ),
  );
}

class ShapeSnapApp extends StatelessWidget {
  const ShapeSnapApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShapeSnap',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/occasions': (context) => const OccasionScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: ShapeSnapApp.analytics),
      ],
    );
  }
}
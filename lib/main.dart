import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/tracker/app_usage_tracker.dart';
import 'features/exceriseSections/viewmodel/match_makring_viewmodel.dart';
import 'features/homePage/viewModel/home_page.dart';
import 'features/splashScreen/view/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/vocabscreen/view/vocab_screen.dart';
import 'features/vocabscreen/viewmodel/vocab_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await SharedPreferences.getInstance();
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize time tracking
  final appUsageTracker = AppUsageTracker();
  await appUsageTracker.resumeTrackingIfNeeded();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => VocabularyProvider()),
        ChangeNotifierProvider(create: (context) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => WordMatchGameViewModel()),

      ],
      child: MyApp(appUsageTracker: appUsageTracker),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppUsageTracker appUsageTracker;

  const MyApp({super.key, required this.appUsageTracker});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start tracking when the app starts
    widget.appUsageTracker.startTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop tracking when the app is disposed
    widget.appUsageTracker.stopTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      widget.appUsageTracker.startTracking();
    } else if (state == AppLifecycleState.paused) {
      // App is not visible
      widget.appUsageTracker.stopTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'German Language Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3F51B5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          secondary: const Color(0xFFFF9800),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          // Heading styles with Montserrat
          displayLarge: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 32,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 28,
          ),
          displaySmall: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
          headlineMedium: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          // Keep Inter for body text
          bodyLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
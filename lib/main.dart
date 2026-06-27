import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/profile_screen.dart';
import 'services/env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EnvLoader.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const JeevSathiApp());
}

class JeevSathiApp extends StatelessWidget {
  const JeevSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeev Sathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // Emerald Green
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFFEF4444), // Crimson Red for SOS
          surface: const Color(0xFFF8FAFC), // Slate 50
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SOSScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initFCMToken();
  }

  /// Requests notification permission, gets the FCM token, and saves it
  /// to Firestore so the Vercel backend can send targeted/broadcast pushes.
  Future<void> _initFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (required on iOS; shows system dialog)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Subscribe to sos_alerts topic (legacy fallback)
      await messaging.subscribeToTopic('sos_alerts');

      // Get the FCM registration token for this device
      final token = await messaging.getToken();
      if (token == null) return;

      // Save token to Firestore against the logged-in user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      debugPrint('FCM token saved for uid: ${user.uid}');

      // Listen for token refresh and update Firestore
      messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('FCM token init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 70,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.home, color: Color(0xFF10B981)),
                label: 'होम',
              ),
              NavigationDestination(
                icon: Icon(Icons.emergency_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.emergency, color: Color(0xFFEF4444)),
                label: 'SOS',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: Colors.grey),
                selectedIcon: Icon(Icons.person, color: Color(0xFF10B981)),
                label: 'प्रोफाइल',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

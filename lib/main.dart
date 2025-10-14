import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';
import 'providers/cart_provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BuccaKingApp());
}

class BuccaKingApp extends StatelessWidget {
  const BuccaKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BuccaKing',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppColors.primary,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  bool _splashCompleted = false;
  late final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _currentUser = _authService.currentUser;
    
    // Show splash for 3 seconds, then switch to real-time auth
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _splashCompleted = true;
        });
        _startAuthListener();
      }
    });
  }

  void _startAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (mounted && _splashCompleted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen initially
    if (_showSplash) {
      return const SplashScreen();
    }

    // Show quick loading if auth state hasn't been determined yet
    if (!_splashCompleted) {
      return _buildQuickLoadingScreen();
    }

    // After splash, show appropriate screen based on auth state
    if (_currentUser != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }

  Widget _buildQuickLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.secondary
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
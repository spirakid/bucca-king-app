import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _circleController;
  late final Animation<double> _logoAnimation;
  late final Animation<double> _textAnimation;
  late final Animation<double> _circleAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
        parent: _logoController, curve: Curves.elasticOut);

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
        parent: _textController, curve: Curves.easeOutCubic);

    _circleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _circleAnimation = CurvedAnimation(
        parent: _circleController, curve: Curves.easeInOut);
  }

  void _startAnimations() {
    Future.delayed(
        const Duration(milliseconds: 300), () => _logoController.forward());
    Future.delayed(
        const Duration(milliseconds: 800), () => _textController.forward());
  }

  void _checkAuthAndNavigate() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final bool isLoggedIn = _authService.isLoggedIn; // keep as getter
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, a1, a2) => isLoggedIn
            ? const HomeScreen()
            : const LoginScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ));
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedCircles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _circleAnimation,
        builder: (context, child) {
          final scale = 0.9 + (_circleAnimation.value * 0.15);
          return Opacity(
            opacity: 0.12,
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withOpacity(0.25),
                      Colors.transparent
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            _buildAnimatedCircles(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('🍽️', style: TextStyle(fontSize: 70))),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.4), end: Offset.zero)
                          .animate(_textAnimation),
                      child: Column(
                        children: [
                          Text('BuccaKing',
                              style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 6),
                          Text('Delicious food delivered fast',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:bucca_king/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _circleController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _circleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _navigateToHome();
  }

  void _setupAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );

    // Circle animation (pulsing effect)
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Animated circles in background
            _buildAnimatedCircles(),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  ScaleTransition(
                    scale: _logoAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child:const Center(
                        child: Text(
                          '🍽️',
                          style: TextStyle(fontSize: 70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Animated text
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(_textAnimation),
                      child: Column(
                        children: [
                          Text(
                            'BuccaKing',
                            style: GoogleFonts.poppins(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Delicious Food Delivered',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Loading indicator
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 3,
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

  Widget _buildAnimatedCircles() {
    return Stack(
      children: [
        // Circle 1
        Positioned(
          top: -50,
          right: -50,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(_circleAnimation),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ),
        // Circle 2
        Positioned(
          bottom: -100,
          left: -100,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.3).animate(_circleAnimation),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ),
        // Circle 3
        Positioned(
          top: 150,
          left: -30,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.1).animate(_circleAnimation),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
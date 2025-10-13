import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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
        home: const SplashScreen(),
      ),
    );
  }
}
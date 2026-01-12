import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'providers/cart_provider.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Color primaryColor = Color(0xFF6B8068);
  final Color secondaryColor = Color(0xFFE8E9C9);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Summ App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'JO')],
      locale: const Locale('ar', 'JO'),
      theme: ThemeData(
        useMaterial3: true,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: primaryColor.withOpacity(0.3),
          selectionHandleColor: primaryColor,
        ),
        textTheme: GoogleFonts.cairoTextTheme(),
      ),
      home: SplashScreen(),
    );
  }
}

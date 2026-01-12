import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
      _startDelay();
    });
  }

  void _startDelay() async {
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
       Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6B8068);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2),
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo1.png',
                width: 110,
                height: 110,

                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.store, size: 80, color: primaryColor);
                },
              ),

              SizedBox(height: 10),

              Image.asset(
                'assets/images/logo.png',

                width: 80,
                height: 16,

                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.store, size: 80, color: primaryColor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

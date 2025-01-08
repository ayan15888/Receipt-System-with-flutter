import 'package:flutter/material.dart';
import 'dart:async';
import 'customer_form.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();


    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomerForm()), // Navigate to CustomerForm
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Splash Image
            CircleAvatar(
              backgroundColor: Colors.greenAccent,
              radius: 90,
              child: Image.asset(
                'assets/images/splash.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),

            // App Name Text
            const Text(
              "Qurashi MeatShop",
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 191, 153, 19),

                fontFamily: 'sans-serif',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/splash_screen.dart
import 'dart:async';

import 'package:evonex/elements/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

 @override
void initState() {
  super.initState();

  _timer = Timer(const Duration(seconds: 4), () {
    if (!mounted) return;
    Get.offAll(() => NewDrawer());
  });
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Splash Image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/splashscreen3.png',
              fit: BoxFit.cover,
            ),
          ),

          // Lottie Animation
          Positioned(
            bottom: 50, // উপরে-নিচে adjust করো
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                
                height: 150,
                child: Lottie.asset(
                  'assets/images/loadballs.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
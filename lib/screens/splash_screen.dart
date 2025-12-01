// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Update this import to your actual home screen path
import 'package:evonex/screens/home_screen.dart';
import 'package:get/get.dart';

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

    // wait 500 milliseconds then navigate to HomeScreen
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Get.to(HomeScreen());
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF5A54), // Top
              Color(0xFFF24671), // Bottom
            ],
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/evonexlogo1.svg', // <-- update if your asset path differs
            height: 40,
          ),
        ),
      ),
    );
  }
}

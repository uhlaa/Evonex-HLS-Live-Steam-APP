
import 'package:evonex/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optionally initialize the engine:
  // await OmniVideoPlayer.ensureInitialized();
   // Lock device orientation to portrait
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HLS Player',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

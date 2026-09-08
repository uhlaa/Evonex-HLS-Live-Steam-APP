import 'package:evonex/elements/my_drawer.dart';
import 'package:evonex/screens/splash_screen.dart';

import 'package:evonex/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://trerjwmxdntvsbgvzvey.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyZXJqd214ZG50dnNiZ3Z6dmV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NTA4NzAsImV4cCI6MjA4MDMyNjg3MH0.m3qAuj2w4_Visg89HFsmrQFkjynBLB6nwzcSZmtIIrE', // replace with env variable / safe storage
  );


  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);


await WakelockPlus.enable();

    runApp(
    MultiProvider(
      providers: [
     

        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    final AdvancedDrawerController _advancedDrawerController =
      AdvancedDrawerController();
      final themeProvider = Provider.of<ThemeProvider>(context);
    return GetMaterialApp(
      title: 'HLS Player',
      theme: themeProvider.themeData,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

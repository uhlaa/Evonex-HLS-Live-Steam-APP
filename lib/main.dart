import 'package:evonex/home_screens.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase safely
  await Supabase.initialize(
    url: 'https://trerjwmxdntvsbgvzvey.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyZXJqd214ZG50dnNiZ3Z6dmV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NTA4NzAsImV4cCI6MjA4MDMyNjg3MH0.m3qAuj2w4_Visg89HFsmrQFkjynBLB6nwzcSZmtIIrE', // replace with env variable / safe storage
  );

  // ✅ Lock orientation to Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      home: HomeScreens(),
    );
  }
}

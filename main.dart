
//import 'package:e_commerce_2/features/signup_screen.dart';
import 'package:e_commerce_2/features/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Supabase.initialize(
    url: 'https://gehsmkgnlipyngnqhska.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlaHNta2dubGlweW5nbnFoc2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMDYxNjAsImV4cCI6MjA4NTg4MjE2MH0.ro8V3QBVcUNvKizMKNNybvsSWmmhLkO2eaEpps_wSQQ',
  );
   runApp(
    const ProviderScope( // <- THIS
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Messenger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AppEntry(), // Corrected line
    );
  }
}




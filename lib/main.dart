import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // inisialisasi supabase ndek project pakai url project sama api key (anon key)
  await Supabase.initialize(
    url: 'https://etkscfmhjlnoiojezvbx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3NjZm1oamxub2lvamV6dmJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MjkzNTYsImV4cCI6MjA1ODQwNTM1Nn0.g8kC6n9UNKQQ9CmRQDzQnFHErOr8XeQzV1U5It30Yoo',
  );

  await NotificationService().initNotification();

  runApp(const MyApp());
}

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Chek autentikasi dulu setelah splash screen buat login /  ke home
    Future.delayed(const Duration(seconds: 2), () {
      final user = Supabase.instance.client.auth.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => user != null 
              ? const HomeScreen() 
              : const LoginScreen(),
        ),
      );
    });

    return  Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/logoscreen.png',height: 150,),
            const SizedBox(height: 16),
            Text(
              "DoManage",
              style: GoogleFonts.montserrat(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: const  Color.fromARGB(255, 143, 41, 239)
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Boost your productivity",style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoManage',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color(0xFFA252ED),
        useMaterial3: true,
      ),
      home: const Splashscreen(),
    );
  }
}
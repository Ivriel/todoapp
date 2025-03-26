import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://etkscfmhjlnoiojezvbx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3NjZm1oamxub2lvamV6dmJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MjkzNTYsImV4cCI6MjA1ODQwNTM1Nn0.g8kC6n9UNKQQ9CmRQDzQnFHErOr8XeQzV1U5It30Yoo',
  );

  await NotificationService().initNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final session = snapshot.data?.session;
          return session != null ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
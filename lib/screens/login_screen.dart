import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isHidden = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final SupabaseService supaService = SupabaseService();
  bool isLogin = true;
  String message = '';

  void authenticate() async {
    try {
      if (isLogin) {
        // Handle Login
        final response = await supaService.signIn(
            emailController.text, passwordController.text);
        if (response.user != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else {
        // Handle Sign Up
        final response = await supaService.signUp(
            emailController.text, passwordController.text);
        if (response.user != null) {
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign up successful! Please login to continue.'),
                backgroundColor: Colors.green,
              ),
            );

            // Clear the text fields
            emailController.clear();
            passwordController.clear();

            // Switch back to login mode
            setState(() {
              isLogin = true;
              message = '';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        message = e.toString();
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email Address',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold
              )
            ,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration:  InputDecoration(
                labelText: 'Enter your email address',
                labelStyle: const TextStyle(
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.black
                    )
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Text(
              'Password',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold
              )
            ,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: isHidden,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                 onPressed: () {
              setState(() {
                isHidden = !isHidden;  // Simply toggle the boolean
              });
            },
                 icon: Icon(
                   isHidden ? Icons.visibility_off : Icons.remove_red_eye,
                )
                ),
                labelText: 'Enter your password',
                 labelStyle: const TextStyle(
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
              ),

            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authenticate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color(0xFFA252ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                )
              ),
              child: Text(
                isLogin ? 'Login' : 'Sign Up',
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w600
                  ),
              ),
            ),
            const SizedBox(height: 16),
            isLogin
                ? Column(
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 15),
                      ),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            message = '';
                            emailController.clear();
                            passwordController.clear();
                          });
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue
                            ),
                        ),
                      ),
                  ],
                )
                : Column(
                  children: [
                    Text("Already have an account? "),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            message = '';
                            emailController.clear();
                            passwordController.clear();
                          });
                        },
                        child: const Text(
                          'Login',
                            style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue
                            ),
                        ),
                      ),
                  ],
                ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

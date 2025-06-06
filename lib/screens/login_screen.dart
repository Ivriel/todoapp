import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final SupabaseService supaService = SupabaseService();
  bool isLogin = true; // setting nilai boolean gawe login atau sign up
  bool isHidden = true; // setting nilai awal gawe hide password
  String message = ''; // gawe kasih pesan error (kalau ada)

  void authenticate() async {
    try {
      if (isLogin) { // kalau true
        // Handle Login
        final response = await supaService.signIn(
            emailController.text, passwordController.text);
        if (response.user != null) { // kalau berhasil login langsung ke home screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else { // kalau false, berarti alihkan ke sign up
 
        final response = await supaService.signUp(
            emailController.text, passwordController.text);
        if (response.user != null) { // kalau pendaftaran berhasil
          if (mounted) {
            //lek iso login  tampilno iki wir
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign up successful! Please login to continue.'),
                backgroundColor: Colors.green,
              ),
            );

            // Bersihkan input
            emailController.clear();
            passwordController.clear();

            // Kalau berhasil sign up arahkan lagi ke login 
            setState(() {
              isLogin = true;
              message = '';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        message = e.toString(); // bakal ada isinya kalau error
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 70),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/logoscreen.png',height: 220,),
                const SizedBox(height: 4),
                Text(
                isLogin?'Login':'Sign Up',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  color: const Color.fromARGB(255, 143, 41, 239),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                textAlign: TextAlign.center,
                isLogin?'Login to your account':'Register your account',
                style: const TextStyle(fontSize: 24)
                ,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Email Address',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Enter your email address',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: isHidden,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isHidden = !isHidden; // SUbah nilai boolean buat hide pw
                          });
                        },
                        icon: Icon(
                          isHidden ? Icons.visibility_off : Icons.remove_red_eye,
                        )),
                    labelText: 'Enter your password',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authenticate,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFA252ED),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(
                    isLogin ? 'Login' : 'Sign Up',
                    style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
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
                                isLogin = !isLogin; // ubah nilai ke false kalau pencet sign up
                                message = '';
                                emailController.clear();
                                passwordController.clear();
                              });
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(fontSize: 13, color: Colors.blue,fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const Text("Already have an account? "),
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
                              style: TextStyle(fontSize: 13, color: Colors.blue,fontWeight: FontWeight.w900),
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
        ),
      ),
    );
  }
}

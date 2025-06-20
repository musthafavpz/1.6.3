// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, avoid_print, prefer_final_fields

import 'dart:convert';
import 'dart:ui';

import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/email_verification_notice.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  // static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool hidePassword = true;
  bool hideConPassword = true;
  bool _isLoading = false;
  String? token;

  // Animation controller
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  SharedPreferences? sharedPreferences;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _conPasswordController = TextEditingController();

  Future<void> signup(
    String name,
    String email,
    String password,
    String password_confirmation,
    BuildContext context, // Added context parameter
  ) async {
    sharedPreferences = await SharedPreferences.getInstance();

    var urls = "$baseUrl/api/signup?type=registration";
    setState(() {
        _isLoading = true;
      });
    try {
      final responses = await http.post(
        Uri.parse(urls),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password_confirmation,
        }),
      );

      if (responses.statusCode == 201) {
        final responseData = jsonDecode(responses.body);

        if (responseData['success'] == true) {
          // Success condition
          if (responseData['student_email_verification'] == "1") {
            // Email verification is required
            Fluttertoast.showToast(
              msg: "Email sent to the user for verification.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 2,
              backgroundColor: Colors.grey,
              textColor: Colors.white,
              fontSize: 16.0,
            );
           setState(() {
        _isLoading = false; // Stop loading
      });

            // Navigate to the email verification page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailVerificationNotice(),
              ),
            );
          } else {
            // No email verification required
            Fluttertoast.showToast(
              msg: "User created successfully",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 2,
              backgroundColor: Colors.grey,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            setState(() {
        _isLoading = false; // Stop loading
      });

            // Navigate to another page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TabsScreen(pageIndex: 1),
              ),
            );
          }
        } else {
          // If 'success' is false
          Fluttertoast.showToast(
            msg: responseData['message'] ?? "Failed to create user.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          setState(() {
        _isLoading = false; // Stop loading
      });
        }
      } else if (responses.statusCode == 422) {
        final responseData = jsonDecode(responses.body);

        if (responseData['validationError'] != null) {
          responseData['validationError'].forEach((key, value) {
            Fluttertoast.showToast(
              msg: value[0], // Display the first error message
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 2,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
           setState(() {
        _isLoading = false; // Stop loading
      });
          });

        }
      } else {
        Fluttertoast.showToast(
          msg: "User Created Successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        setState(() {
          _isLoading = false; // Stop loading
        });
        
        // Redirect to login page
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (error) {
      print('Error: $error');
    }finally{
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  void initState() {
    // isLogin();
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _conPasswordController.dispose();
    super.dispose();
  }

  InputDecoration getInputDecoration(String hintext, IconData icon) {
    return InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: const Color(0xFF6366F1), width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Color(0xFFF65054)),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Color(0xFFF65054)),
      ),
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
      hintText: hintext,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6366F1),
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle design elements
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                ),
              ),
            ),
            
            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),

            // Main content
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: globalFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 60),
                              // App Logo
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/light_logo.png',
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(height: 40),
                              
                              // Welcome Text
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF333333),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Sign up to start your learning journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 40),

                              // Form Fields
                              TextFormField(
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                                decoration: getInputDecoration('Full Name', Icons.person_rounded),
                                controller: _nameController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              TextFormField(
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                                decoration: getInputDecoration('Email Address', Icons.email_rounded),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (input) => !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                    .hasMatch(input!)
                                    ? "Please enter a valid email address"
                                    : null,
                              ),
                              SizedBox(height: 20),

                              TextFormField(
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                                controller: _passwordController,
                                obscureText: hidePassword,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                                decoration: getInputDecoration('Password', Icons.lock_rounded).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => hidePassword = !hidePassword),
                                    color: Colors.grey.shade500,
                                    icon: Icon(hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              TextFormField(
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                                controller: _conPasswordController,
                                obscureText: hideConPassword,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                decoration: getInputDecoration('Confirm Password', Icons.lock_rounded).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => hideConPassword = !hideConPassword),
                                    color: Colors.grey.shade500,
                                    icon: Icon(hideConPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(height: 40),

                              // Sign Up Button
                              if (_isLoading)
                                Container(
                                  height: 56,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFF6366F1),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (globalFormKey.currentState!.validate()) {
                                        signup(
                                          _nameController.text,
                                          _emailController.text,
                                          _passwordController.text,
                                          _conPasswordController.text,
                                          context,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.transparent.withOpacity(0.38),
                                      disabledBackgroundColor: Colors.transparent.withOpacity(0.12),
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),

                              SizedBox(height: 40),
                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: const Color(0xFF6366F1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

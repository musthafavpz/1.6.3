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
  static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
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
    BuildContext context,
  ) async {
    if (!_validateInputs()) return;
  
    setState(() {
      _isLoading = true;
    });
    
    sharedPreferences = await SharedPreferences.getInstance();
    var urls = "$baseUrl/api/signup?type=registration";
    
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
          if (responseData['student_email_verification'] == "1") {
            // Email verification is required
            _showSuccessToast("Email sent for verification. Please verify your email.");
            setState(() {
              _isLoading = false;
            });
            
            // Navigate to the email verification page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailVerificationNotice(),
              ),
            );
          } else {
            // No email verification required
            _showSuccessToast("Account created successfully!");
            
            // Automatically log in after signup
            await _autoLogin(email, password);
          }
        } else {
          _showErrorToast(responseData['message'] ?? "Failed to create user.");
          setState(() {
            _isLoading = false;
          });
        }
      } else if (responses.statusCode == 422) {
        final responseData = jsonDecode(responses.body);

        if (responseData['validationError'] != null) {
          String errorMessage = "";
          responseData['validationError'].forEach((key, value) {
            errorMessage = value[0]; // Display the first error message
          });
          _showErrorToast(errorMessage);
          setState(() {
            _isLoading = false;
          });
        } else {
          _showErrorToast("Validation error occurred.");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Handle other status codes
        _showErrorToast("An error occurred. Please try again.");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error: $error');
      _showErrorToast("Connection error. Please check your internet connection.");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Auto-login after successful signup
  Future<void> _autoLogin(String email, String password) async {
    try {
      var loginUrl = "$baseUrl/api/login";
      var loginResponse = await http.post(
        Uri.parse(loginUrl),
        body: {
          "email": email,
          "password": password,
        },
      );
      
      if (loginResponse.statusCode == 201) {
        final data = jsonDecode(loginResponse.body);
        final user = data["user"];
        
        // Store user data in SharedPreferences
        sharedPreferences!.setString("access_token", data["token"]);
        sharedPreferences!.setString("user", jsonEncode(user));
        sharedPreferences!.setString("email", email);
        sharedPreferences!.setString("password", password);
        
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const TabsScreen(
              pageIndex: 0,
            ),
          ),
        );
      } else {
        // Login failed but account was created
        setState(() {
          _isLoading = false;
        });
        _showSuccessToast("Account created! Please log in.");
        Navigator.of(context).pop(); // Go back to welcome screen
      }
    } catch (e) {
      // Error during auto-login
      print("Auto-login error: $e");
      setState(() {
        _isLoading = false;
      });
      _showSuccessToast("Account created! Please log in.");
      Navigator.of(context).pop(); // Go back to welcome screen
    }
  }
  
  bool _validateInputs() {
    if (_nameController.text.isEmpty) {
      _showErrorToast("Name field cannot be empty");
      return false;
    }
    
    if (_emailController.text.isEmpty) {
      _showErrorToast("Email field cannot be empty");
      return false;
    }
    
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_emailController.text)) {
      _showErrorToast("Please enter a valid email address");
      return false;
    }
    
    if (_passwordController.text.isEmpty) {
      _showErrorToast("Password field cannot be empty");
      return false;
    }
    
    if (_passwordController.text.length < 8) {
      _showErrorToast("Password must be at least 8 characters long");
      return false;
    }
    
    if (_passwordController.text != _conPasswordController.text) {
      _showErrorToast("Passwords do not match");
      return false;
    }
    
    return true;
  }
  
  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
  
  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void initState() {
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
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: const Color(0xFF6366F1), size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 10),
                            // Title
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
                              'Join our learning community',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 40),
                            
                            // Registration Form
                            Form(
                              key: globalFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Name field
                                  TextFormField(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: getInputDecoration(
                                      'Full Name',
                                      Icons.person_outline,
                                    ),
                                    controller: _nameController,
                                  ),
                                  SizedBox(height: 20),
                                  
                                  // Email field
                                  TextFormField(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: getInputDecoration(
                                      'Email Address',
                                      Icons.email_outlined,
                                    ),
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  SizedBox(height: 20),
                                  
                                  // Password field
                                  TextFormField(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    keyboardType: TextInputType.text,
                                    controller: _passwordController,
                                    obscureText: hidePassword,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: const Color(0xFF6366F1), width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                      ),
                                      filled: true,
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                      hintText: "Password",
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: const Color(0xFF6366F1),
                                        size: 22,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            hidePassword = !hidePassword;
                                          });
                                        },
                                        color: Colors.grey.shade500,
                                        icon: Icon(
                                          hidePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  
                                  // Confirm Password field
                                  TextFormField(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    keyboardType: TextInputType.text,
                                    controller: _conPasswordController,
                                    obscureText: hideConPassword,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: const Color(0xFF6366F1), width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                      ),
                                      filled: true,
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                      hintText: "Confirm Password",
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: const Color(0xFF6366F1),
                                        size: 22,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            hideConPassword = !hideConPassword;
                                          });
                                        },
                                        color: Colors.grey.shade500,
                                        icon: Icon(
                                          hideConPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
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
                                          signup(
                                            _nameController.text.toString(),
                                            _emailController.text.toString(),
                                            _passwordController.text.toString(),
                                            _conPasswordController.text.toString(),
                                            context,
                                          );
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
                                          'SIGN UP',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                  SizedBox(height: 30),
                                  // Already have an account
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
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "Login",
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
                          ],
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

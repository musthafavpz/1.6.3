// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:ui';

import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/email_verification_notice.dart';
import 'package:academy_lms_app/screens/forget_password.dart';
import 'package:academy_lms_app/screens/signup.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool hidePassword = true;
  bool _isLoading = false;
  String? token;
  
  // Animation controller
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  SharedPreferences? sharedPreferences;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  getLogin() async {
    setState(() {
      _isLoading = true;
    });

    String link = "$baseUrl/api/login";
    var navigator = Navigator.of(context);
    sharedPreferences = await SharedPreferences.getInstance();

    var map = <String, dynamic>{};
    map["email"] = _emailController.text.toString();
    map["password"] = _passwordController.text.toString();

    try {
      var response = await http.post(
        Uri.parse(link),
        body: map,
      );

      setState(() {
        _isLoading = false;
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final user = data["user"];
        final emailVerifiedAt = user["email_verified_at"];

        if (emailVerifiedAt != null) {
          // If email is verified, proceed with login
          setState(() {
            sharedPreferences!.setString("access_token", data["token"]);
            sharedPreferences!.setString("user", jsonEncode(user));
            sharedPreferences!.setString("email", _emailController.text.toString());
            sharedPreferences!.setString("password", _passwordController.text.toString());
          });
          token = sharedPreferences!.getString("access_token");
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const TabsScreen(
                pageIndex: 0,
              ),
            ),
          );
          Fluttertoast.showToast(msg: "Login Successful");
        } else {
          // If email is not verified, navigate to the email verification page
          Fluttertoast.showToast(
            msg: "Please verify your email before logging in.",
          );
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => EmailVerificationNotice(),
            ),
          );
        }
      } else {
        Fluttertoast.showToast(msg: data['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "An error occurred: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  isLogin() async {
    var navigator = Navigator.of(context);
    sharedPreferences = await SharedPreferences.getInstance();
    token = sharedPreferences!.getString("access_token");
    try {
      if (token == null) {
        // print("Token is Null");
      } else {
        Fluttertoast.showToast(msg: "Welcome Back");
        navigator.pushReplacement(MaterialPageRoute(
            builder: (context) => const TabsScreen(
                  pageIndex: 0,
                )));
      }
    } catch (e) {
      // print("Exception is $e");
    }
  }

  @override
  void initState() {
    super.initState();
    isLogin();
    
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
        borderSide: BorderSide(color: kDefaultColor, width: 1),
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
        color: kDefaultColor,
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
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
                  color: kDefaultColor.withOpacity(0.05),
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
                  color: kDefaultColor.withOpacity(0.05),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),
                            // App Logo
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: 40),
                            
                            // Welcome Text
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Login to continue your learning journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 60),
                            
                            // Login Form
                            Form(
                              key: globalFormKey,
                              child: Column(
                                children: [
                                  // Email TextField
                                  TextFormField(
                                    style: TextStyle(
                                      fontSize: 16, 
                                      color: Colors.black87,
                                    ),
                                    decoration: getInputDecoration(
                                      'Email Address',
                                      Icons.email_rounded,
                                    ),
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (input) =>
                                        !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                                .hasMatch(input!)
                                            ? "Email should be valid"
                                            : null,
                                  ),
                                  SizedBox(height: 20),
                                  
                                  // Password TextField
                                  TextFormField(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    keyboardType: TextInputType.text,
                                    controller: _passwordController,
                                    validator: (input) => input!.length < 3
                                        ? "Password should be more than 3 characters"
                                        : null,
                                    obscureText: hidePassword,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: kDefaultColor, width: 1),
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
                                        Icons.lock_rounded,
                                        color: kDefaultColor,
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
                                              : Icons.visibility_outlined
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 15),
                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ForgetPassword(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: kDefaultColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 40),
                                  // Login Button
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
                                          color: kDefaultColor,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: kDefaultColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kDefaultColor.withOpacity(0.25),
                                            blurRadius: 20,
                                            offset: Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_emailController.text.isNotEmpty &&
                                              _passwordController.text.isNotEmpty) {
                                            getLogin();
                                          } else if (_emailController.text.isEmpty) {
                                            Fluttertoast.showToast(
                                                msg: "Email field cannot be empty");
                                          } else if (_passwordController.text.isEmpty) {
                                            Fluttertoast.showToast(
                                                msg: "Password field cannot be empty");
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: "Email & password field cannot be empty");
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
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 40),
                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: kDefaultColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
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

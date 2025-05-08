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
        borderSide: BorderSide(color: Colors.transparent, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: kDefaultColor.withOpacity(0.5), width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Colors.transparent, width: 1),
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
      hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
      hintText: hintext,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      prefixIcon: Icon(
        icon,
        color: kDefaultColor.withOpacity(0.7),
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -screenSize.height * 0.1,
                right: -screenSize.width * 0.4,
                child: Container(
                  height: screenSize.height * 0.5,
                  width: screenSize.height * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: -screenSize.height * 0.15,
                left: -screenSize.width * 0.2,
                child: Container(
                  height: screenSize.height * 0.4,
                  width: screenSize.height * 0.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
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
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: screenSize.height * 0.05,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Form(
                              key: globalFormKey,
                              child: Padding(
                                padding: const EdgeInsets.all(25.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 10),
                                    Container(
                                      height: 80,
                                      width: 80,
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
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          height: 60,
                                          width: 60,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Login to continue learning',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    SizedBox(height: 40),
                                    TextFormField(
                                      style: const TextStyle(
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
                                    TextFormField(
                                      style: const TextStyle(
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
                                          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                          borderSide: BorderSide(color: Colors.transparent, width: 1),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                          borderSide: BorderSide(color: kDefaultColor.withOpacity(0.5), width: 1),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                          borderSide: BorderSide(color: Colors.transparent, width: 1),
                                        ),
                                        filled: true,
                                        hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
                                        hintText: "Password",
                                        fillColor: Colors.white.withOpacity(0.9),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                        prefixIcon: Icon(
                                          Icons.lock_rounded,
                                          color: kDefaultColor.withOpacity(0.7),
                                          size: 22,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              hidePassword = !hidePassword;
                                            });
                                          },
                                          color: kInputBoxIconColor,
                                          icon: Icon(
                                            hidePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 15),
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
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    _isLoading
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFFF8A00),
                                                Color(0xFFFF0080),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFFFF0080).withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: Offset(0, 5),
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
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    SizedBox(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            color: Colors.white,
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
                                            'Sign Up',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
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
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

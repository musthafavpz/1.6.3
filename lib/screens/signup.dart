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
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
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
        borderSide: BorderSide(color: Color(0xFFFF0080).withOpacity(0.5), width: 1),
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
        color: Color(0xFFFF0080).withOpacity(0.7),
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Color(0xFFFF0080)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF8A00),
              Color(0xFFFF0080),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -screenSize.height * 0.15,
                right: -screenSize.width * 0.3,
                child: Container(
                  height: screenSize.height * 0.4,
                  width: screenSize.height * 0.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: -screenSize.height * 0.1,
                left: -screenSize.width * 0.3,
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
                        child: SingleChildScrollView(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            padding: const EdgeInsets.all(25),
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
                            child: Form(
                              key: globalFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Title
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Join our learning community',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  // Name field
                                  TextFormField(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: getInputDecoration(
                                      'Full Name',
                                      Icons.person_outline,
                                    ),
                                    controller: _nameController,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your full name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Email field
                                  TextFormField(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: getInputDecoration(
                                      'Email Address',
                                      Icons.email_outlined,
                                    ),
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (input) =>
                                        !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                                .hasMatch(input!)
                                            ? "Email should be valid"
                                            : null,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Password field
                                  TextFormField(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    keyboardType: TextInputType.text,
                                    controller: _passwordController,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter min 8 character password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters long';
                                      }
                                      return null;
                                    },
                                    obscureText: hidePassword,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.transparent, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Color(0xFFFF0080).withOpacity(0.5), width: 1),
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
                                        Icons.lock_outline,
                                        color: Color(0xFFFF0080).withOpacity(0.7),
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
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Confirm Password field
                                  TextFormField(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    keyboardType: TextInputType.text,
                                    controller: _conPasswordController,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    obscureText: hideConPassword,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.transparent, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Color(0xFFFF0080).withOpacity(0.5), width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                        borderSide: BorderSide(color: Colors.transparent, width: 1),
                                      ),
                                      filled: true,
                                      hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
                                      hintText: "Confirm Password",
                                      fillColor: Colors.white.withOpacity(0.9),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Color(0xFFFF0080).withOpacity(0.7),
                                        size: 22,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            hideConPassword = !hideConPassword;
                                          });
                                        },
                                        color: kInputBoxIconColor,
                                        icon: Icon(
                                          hideConPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  // Sign Up Button
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius:
                                                    10,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (_nameController.text.isEmpty) {
                                                Fluttertoast.showToast(
                                                    msg: "Name field cannot be empty");
                                              } else if (_emailController.text.isEmpty) {
                                                Fluttertoast.showToast(
                                                    msg: "Email field cannot be empty");
                                              } else if (_passwordController.text.isEmpty) {
                                                Fluttertoast.showToast(
                                                    msg: "Password field cannot be empty");
                                              } else if (_conPasswordController.text.isEmpty) {
                                                Fluttertoast.showToast(
                                                    msg: "Confirm Password field cannot be empty");
                                              } else if (_passwordController.text !=
                                                  _conPasswordController.text) {
                                                Fluttertoast.showToast(
                                                    msg: "Confirm password not matched");
                                              } else {
                                                signup(
                                                    _nameController.text,
                                                    _emailController.text,
                                                    _passwordController.text,
                                                    _conPasswordController.text,
                                                    context);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFFFF0080),
                                              disabledForegroundColor:
                                                  Colors.transparent.withOpacity(0.38),
                                              disabledBackgroundColor:
                                                  Colors.transparent.withOpacity(0.12),
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
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 20),
                                  
                                  // Already have account
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account? ",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                ],
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

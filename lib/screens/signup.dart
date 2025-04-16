import 'dart:convert';
import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/email_verification_notice.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
          if (responseData['student_email_verification'] == "1") {
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
              _isLoading = false;
            });

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailVerificationNotice(),
              ),
            );
          } else {
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
              _isLoading = false;
            });

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TabsScreen(pageIndex: 1),
              ),
            );
          }
        } else {
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
            _isLoading = false;
          });
        }
      } else if (responses.statusCode == 422) {
        final responseData = jsonDecode(responses.body);

        if (responseData['validationError'] != null) {
          responseData['validationError'].forEach((key, value) {
            Fluttertoast.showToast(
              msg: value[0],
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 2,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            setState(() {
              _isLoading = false;
            });
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "User Account Created Successfully! Go to Login",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: kDefaultColor, width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Color(0xFFF65054), width: 1),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: Color(0xFFF65054), width: 1),
      ),
      filled: true,
      prefixIcon: Icon(icon, color: kDefaultColor.withOpacity(0.7)),
      hintStyle: TextStyle(color: Colors.black38, fontSize: 15, fontWeight: FontWeight.w400),
      hintText: hintext,
      fillColor: kInputBoxBackGroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: globalFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.arrow_back_ios_new, size: 20, color: kDefaultColor),
                            ),
                          ),
                          Spacer(),
                          Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/images/app_logo.png", 
                                height: 28, 
                                width: 28,
                                // Replace with your actual app logo
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: size.height * 0.06),
                      
                      // Header Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sign up to get started with learning',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: size.height * 0.05),
                      
                      // Form Fields
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              style: const TextStyle(fontSize: 15),
                              decoration: getInputDecoration('Full Name', Icons.person_outline),
                              controller: _nameController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                setState(() {
                                  _nameController.text = value as String;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              style: const TextStyle(fontSize: 15),
                              decoration: getInputDecoration('Email Address', Icons.email_outlined),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (input) =>
                                  !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                          .hasMatch(input!)
                                      ? "Email address should be valid"
                                      : null,
                              onSaved: (value) {
                                setState(() {
                                  _emailController.text = value as String;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              style: const TextStyle(fontSize: 15),
                              keyboardType: TextInputType.text,
                              controller: _passwordController,
                              onSaved: (input) {
                                setState(() {
                                  _passwordController.text = input as String;
                                });
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter min 8 character password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                              obscureText: hidePassword,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: kDefaultColor, width: 1),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Color(0xFFF65054), width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Color(0xFFF65054), width: 1),
                                ),
                                filled: true,
                                prefixIcon: Icon(Icons.lock_outline, color: kDefaultColor.withOpacity(0.7)),
                                hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                                hintText: "Password",
                                fillColor: kInputBoxBackGroundColor,
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                                  color: kInputBoxIconColor,
                                  icon: Icon(hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              style: const TextStyle(fontSize: 15),
                              keyboardType: TextInputType.text,
                              controller: _conPasswordController,
                              onSaved: (input) {
                                setState(() {
                                  _conPasswordController.text = input as String;
                                });
                              },
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
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: kDefaultColor, width: 1),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Color(0xFFF65054), width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                  borderSide: BorderSide(color: Color(0xFFF65054), width: 1),
                                ),
                                filled: true,
                                prefixIcon: Icon(Icons.lock_outline, color: kDefaultColor.withOpacity(0.7)),
                                hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                                hintText: "Confirm Password",
                                fillColor: kInputBoxBackGroundColor,
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      hideConPassword = !hideConPassword;
                                    });
                                  },
                                  color: kInputBoxIconColor,
                                  icon: Icon(hideConPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Sign Up Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: _isLoading 
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [
                                  Color(0xFFEC6800),
                                  Color(0xFFFFA500),
                                ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kDefaultColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoading 
                              ? null 
                              : () async {
                                  if (globalFormKey.currentState!.validate()) {
                                    signup(
                                      _nameController.text,
                                      _emailController.text,
                                      _passwordController.text,
                                      _conPasswordController.text,
                                      context
                                    );
                                  }
                                },
                            child: Center(
                              child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 25),
                      
                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 15,
                                color: kDefaultColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously, avoid_print, unused_field

import 'dart:convert';
import 'dart:io';

import 'package:academy_lms_app/widgets/appbar_one.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';
import '../providers/auth.dart';
import '../widgets/common_functions.dart';
import '../widgets/custom_text.dart';

class EditPrfileScreen extends StatefulWidget {
  const EditPrfileScreen({super.key});

  @override
  State<EditPrfileScreen> createState() => _EditPrfileScreenState();
}

class _EditPrfileScreenState extends State<EditPrfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  bool _isLoading = false;
  SharedPreferences? sharedPreferences;
  Map<String, dynamic>? user;

  final Map<String, String> _userData = {
    'name': '',
    'biography': '',
    'about': '',
    'address': '',
    'twitter': '',
    'facebook': '',
    'linkedin': '',
  };

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  getUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    sharedPreferences = await SharedPreferences.getInstance();
    var userDetails = sharedPreferences!.getString("user");
    if (userDetails != null) {
      try {
        setState(() {
          user = jsonDecode(userDetails) as Map<String, dynamic>? ?? {};
        });
      } catch (e) {
        print('Error decoding user details: $e');
        user = {}; // Default to an empty map
      }
    } else {
      user = {}; // Default to an empty map if no user details are found
    }

    setState(() {
      _isLoading = false;
    });
  }

  InputDecoration getInputDecoration(String hintext) {
    return InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: kDefaultColor.withOpacity(0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: kDefaultColor.withOpacity(0.1), width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: kDefaultColor.withOpacity(0.1), width: 1),
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
      fillColor: kInputBoxBackGroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    );
  }

  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid form
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure default empty string if null
      final id = _userData['id']?.isNotEmpty ?? false
          ? _userData['id']!
          : user?['id'] ?? '';
      final name = _userData['name']?.isNotEmpty ?? false
          ? _userData['name']!
          : user?['name'] ?? '';
      final phone = _userData['phone']?.isNotEmpty ?? false
          ? _userData['phone']!
          : user?['phone'] ?? '';
      final biography = _userData['biography']?.isNotEmpty ?? false
          ? _userData['biography']!
          : user?['biography'] ?? '';
      final about = _userData['about']?.isNotEmpty ?? false
          ? _userData['about']!
          : user?['about'] ?? '';
      final address = _userData['address']?.isNotEmpty ?? false
          ? _userData['address']!
          : user?['address'] ?? '';
      final twitter = _userData['twitter']?.isNotEmpty ?? false
          ? _userData['twitter']!
          : user?['twitter'] ?? '';
      final facebook = _userData['facebook']?.isNotEmpty ?? false
          ? _userData['facebook']!
          : user?['facebook'] ?? '';
      final linkedin = _userData['linkedin']?.isNotEmpty ?? false
          ? _userData['linkedin']!
          : user?['linkedin'] ?? '';

      // Handle image selection
      final photo = _image != null ? _image!.path : user?['photo'] ?? '';
      print(photo);

      // Create updated user object

      User updateUser;

      if (_image != null) {
        // If an image is selected, include the photo field
        updateUser = User(
          name: name,
          biography: biography,
          about: about,
          address: address,
          twitter: twitter,
          facebook: facebook,
          linkedIn: linkedin,
          photo: photo, // Include the photo field
        );
      } else {
        // If no image is selected, do not include the photo field
        updateUser = User(
          name: name,
          biography: biography,
          about: about,
          address: address,
          twitter: twitter,
          facebook: facebook,
          linkedIn: linkedin,
        );
      }

      // Update user data in the backend
      await Provider.of<Auth>(context, listen: false)
          .updateUserData(updateUser);

      // Update shared preferences with new user data
      user = {
        'id': id,
        'name': name,
        'phone': phone,
        'photo': photo,
        'biography': biography,
        'about': about,
        'address': address,
        'twitter': twitter,
        'facebook': facebook,
        'linkedin': linkedin,
      };

      // sharedPreferences = await SharedPreferences.getInstance();
      // await sharedPreferences!.setString("user", jsonEncode(user));

      // Show success message
      CommonFunctions.showSuccessToast('User updated Successfully');

      // Pop the screen and return true
      Navigator.pop(context, true);
    } on HttpException {
      var errorMsg = 'Update failed e';
      CommonFunctions.showErrorDialog(errorMsg, context);
    } catch (error) {
      const errorMsg = 'Update failed!';
      CommonFunctions.showErrorDialog(errorMsg, context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppBarOne(title: 'Update Profile'),
      body: Container(
        height: MediaQuery.of(context).size.height * 1,
        color: const Color(0xFFF8F9FA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kDefaultColor),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Image Section with Gradient
                      Container(
                        padding: const EdgeInsets.all(16),
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
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  ClipOval(
                                    child: InkWell(
                                      onTap: () {
                                        _pickImage();
                                      },
                                      child: Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: CircleAvatar(
                                            radius: 55,
                                            backgroundImage: _image != null
                                                ? FileImage(_image!) as ImageProvider<Object>?
                                                : (user != null && user!['photo'] is String
                                                    ? NetworkImage(user!['photo'] as String) as ImageProvider<Object>?
                                                    : null),
                                            backgroundColor: kDefaultColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    bottom: 0,
                                    child: Container(
                                      height: 45,
                                      width: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: ClipOval(
                                          child: FloatingActionButton(
                                            elevation: 0,
                                            onPressed: () {
                                              _pickImage();
                                            },
                                            tooltip: 'Choose Image',
                                            backgroundColor: const Color(0xFF6366F1),
                                            child: const Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Update Profile Picture',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Form Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Form Fields
                              _buildFormField(
                                label: 'User Name',
                                initialValue: user?['name'] ?? '',
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Name cannot be empty';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _userData['name'] = value ?? '';
                                },
                              ),
                              _buildFormField(
                                label: 'Biography',
                                initialValue: user?['biography'] ?? '',
                                maxLines: 3,
                                onSaved: (value) {
                                  _userData['biography'] = value ?? '';
                                },
                              ),
                              _buildFormField(
                                label: 'About',
                                initialValue: user?['about'] ?? '',
                                maxLines: 3,
                                onSaved: (value) {
                                  _userData['about'] = value ?? '';
                                },
                              ),
                              _buildFormField(
                                label: 'Address',
                                initialValue: user?['address'] ?? '',
                                onSaved: (value) {
                                  _userData['address'] = value ?? '';
                                },
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Social Media Links',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildFormField(
                                label: 'Twitter',
                                initialValue: user?['twitter'] ?? '',
                                onSaved: (value) {
                                  _userData['twitter'] = value ?? '';
                                },
                              ),
                              _buildFormField(
                                label: 'Facebook',
                                initialValue: user?['facebook'] ?? '',
                                onSaved: (value) {
                                  _userData['facebook'] = value ?? '';
                                },
                              ),
                              _buildFormField(
                                label: 'LinkedIn',
                                initialValue: user?['linkedin'] ?? '',
                                onSaved: (value) {
                                  _userData['linkedin'] = value ?? '';
                                },
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : MaterialButton(
                                        onPressed: _submit,
                                        height: 50,
                                        color: const Color(0xFF6366F1),
                                        textColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Update Profile',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String initialValue,
    int maxLines = 1,
    String? Function(String?)? validator,
    required Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF65054), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF65054), width: 1),
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

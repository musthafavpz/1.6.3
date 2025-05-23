// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/user.dart';

class Auth with ChangeNotifier {
  String? _token;
  String? _userId;
  // ignore: prefer_final_fields
  User _user = User(userId: '', name: '', email: '', role: '');

  String? get token {
    if (_token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    if (_userId != null) {
      return _userId;
    }
    return null;
  }

  User get user {
    return _user;
  }

  Future<void> logout() async {
    _token = null;
    // _user = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    // Remove all user-related data
    prefs.remove('access_token');
    prefs.remove('user_name');
    prefs.remove('user_photo');
    prefs.remove('school_name');
    prefs.remove('user');
    prefs.remove('email');
    prefs.remove('password');
    // Don't clear onboarding_completed so users don't see onboarding again
  }

  Future<void> updateUserPassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    const url = '$baseUrl/api/update_password';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final responseData = json.decode(response.body);
      if (responseData['status'] == 'failed') {
        throw HttpException(responseData['message']);
      }
    } catch (error) {
      rethrow;
    }
  }

Future<void> updateUserData(User user) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';
  const url = '$baseUrl/api/update_userdata';

  try {
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Set headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    if (user.name != null) request.fields['name'] = user.name!;
    if (user.biography != null) request.fields['biography'] = user.biography!;
    if (user.about != null) request.fields['about'] = user.about!;
    if (user.address != null) request.fields['address'] = user.address!;
    if (user.twitter != null) request.fields['twitter'] = user.twitter!;
    if (user.facebook != null) request.fields['facebook'] = user.facebook!;
    if (user.linkedIn != null) request.fields['linkedin'] = user.linkedIn!;

    // Add image file
    if (user.photo.toString() != "null") {
      try {
        request.files.add(await http.MultipartFile.fromPath('photo', user.photo!));
      } catch (e) {
        print('Error adding photo: $e');
        throw const HttpException('Photo Upload Failed');
      }
    }

    // Send request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    // Decode response
    final responseData = jsonDecode(responseBody);

    if (response.statusCode != 200 || responseData['status'] == 'failed') {
      print('Response error: ${response.statusCode}');
      print('Response body: $responseBody');
      throw const HttpException('Update Failed 1');
    }

    // Update shared preferences
    await prefs.setString("user", jsonEncode(responseData["user"]));

    // Notify listeners
    notifyListeners();
  } catch (error) {
    print('Error updating user data: $error');
    rethrow;
  }
}

  // Future<void> updateUserData(User user) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = (prefs.getString('access_token') ?? '');
  //   const url = '$baseUrl/api/update_userdata';

  //   try {
  //     final request = http.MultipartRequest('POST', Uri.parse(url));

  //     request.headers['Authorization'] = 'Bearer $token';
  //     request.fields['name'] = user.name!;
  //     request.fields['biography'] = user.biography!;
  //     request.fields['about'] = user.about!;
  //     request.fields['address'] = user.address!;
  //     request.fields['twitter'] = user.twitter!;
  //     request.fields['facebook'] = user.facebook!;
  //     request.fields['linkedin'] = user.linkedIn!;

  //     // Add images to the request as files
  //     if (user.photo.toString() != "null") {
  //       request.files
  //           .add(await http.MultipartFile.fromPath('photo', user.photo!));
  //     }

  //     final response = await request.send();
  //     final responseBody = await response.stream.bytesToString();

  //     final responseData = jsonDecode(responseBody);

  //     // final response = await http.post(Uri.parse(url),
  //     //   headers: {
  //     //     'Content-Type': 'application/json',
  //     //     'Accept': 'application/json',
  //     //     'Authorization': 'Bearer $authToken',
  //     //   },
  //     //   body: json.encode({
  //     //     'name': user.name,
  //     //     'biography': user.biography,
  //     //     'about': user.about,
  //     //     'address': user.address,
  //     //     'twitter': user.twitter,
  //     //     'facebook': user.facebook,
  //     //     'linkedin': user.linkedIn,
  //     //   }),
  //     // );
  //     // final responseData = json.decode(response.body);

  //     // print(responseData);
  //     if (responseData['status'] == 'failed') {
  //       throw const HttpException('Update Failed');
  //     }

  //     SharedPreferences? sharedPreferences;
  //     sharedPreferences = await SharedPreferences.getInstance();

  //     sharedPreferences.setString("user", jsonEncode(responseData["user"]));

  //     notifyListeners();
  //   } catch (error) {
  //     rethrow;
  //   }
  // }
}

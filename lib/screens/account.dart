// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/auth.dart';
import '../widgets/custom_text.dart';
import 'account_remove_screen.dart';
import 'edit_profile.dart';
import 'my_wishlist.dart';
import 'update_password.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = false;
  bool _dataUpdated = false;
  SharedPreferences? sharedPreferences;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });

    sharedPreferences = await SharedPreferences.getInstance();
    var userDetails = sharedPreferences!.getString("user");

    if (userDetails != null) {
      try {
        setState(() {
          user = jsonDecode(userDetails);
        });
      } catch (e) {
        print('Error decoding user details: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dataUpdated) {
      getData();
      _dataUpdated = false; // Reset the flag
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackGroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            )
          : user == null
              ? const Center(child: Text('No user data available'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile header with gradient background
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              kDefaultColor,
                              kDefaultColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kDefaultColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.only(
                            top: 60, bottom: 30, left: 20, right: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundImage: user?['photo'] != null
                                        ? NetworkImage(user!['photo'])
                                        : null,
                                    backgroundColor: Colors.white,
                                    child: user?['photo'] == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 55,
                                            color: kGreyLightColor,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const EditPrfileScreen(),
                                          ));
                                      if (result == true) {
                                        setState(() {
                                          _dataUpdated = true;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: kDefaultColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              user?['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              user!['phone'] ?? "No Phone number",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Account options
                      Container(
                        width: size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildProfileOption(
                              title: 'Edit Profile',
                              icon: 'assets/icons/profile.svg',
                              onTap: () async {
                                final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditPrfileScreen(),
                                    ));
                                if (result == true) {
                                  setState(() {
                                    _dataUpdated = true;
                                  });
                                }
                              },
                              iconColor: Colors.blue,
                            ),
                            _divider(),
                            _buildProfileOption(
                              title: 'My Wishlists',
                              icon: 'assets/icons/wishlist.svg',
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyWishlistScreen(),
                                    ));
                              },
                              iconColor: Colors.red,
                            ),
                            _divider(),
                            _buildProfileOption(
                              title: 'Change Password',
                              icon: 'assets/icons/key.svg',
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UpdatePasswordScreen(),
                                    ));
                              },
                              iconColor: Colors.amber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Account management
                      Container(
                        width: size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildProfileOption(
                              title: 'Delete Your Account',
                              icon: 'assets/icons/profile.svg',
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(AccountRemoveScreen.routeName);
                              },
                              iconColor: Colors.grey,
                              textColor: Colors.red,
                            ),
                            _divider(),
                            _buildProfileOption(
                              title: 'Log Out',
                              icon: 'assets/icons/logout.svg',
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => _buildLogoutDialog(context),
                                );
                              },
                              iconColor: Colors.red,
                              textColor: Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // About section
                      Container(
                        width: size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _buildProfileOption(
                          title: 'About',
                          icon: 'assets/icons/about.svg',
                          onTap: () {},
                          iconColor: kDefaultColor,
                          showSubtitle: true,
                          subtitle: "Version: 1.3.0",
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required String icon,
    required VoidCallback onTap,
    Color iconColor = kDefaultColor,
    Color textColor = Colors.black87,
    bool showSubtitle = false,
    String subtitle = "",
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                icon,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (showSubtitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kGreyLightColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: kGreyLightColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        thickness: 1,
        color: kGreyLightColor.withOpacity(0.2),
        height: 1,
      ),
    );
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kDefaultColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              width: double.infinity,
              child: const Column(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Log Out?",
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Are you sure, You want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: kTextColor,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: kPrimaryColor),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<Auth>(context, listen: false).logout().then(
                            (_) => Navigator.pushNamedAndRemoveUntil(
                                context, '/home', (r) => false));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

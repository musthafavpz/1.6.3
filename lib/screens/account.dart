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

// Updated color palette for premium look
const Color kPremiumDark = Color(0xFF1E2033);
const Color kPremiumAccent = Color(0xFF6C63FF);
const Color kPremiumBackground = Color(0xFFF8F9FD);
const Color kPremiumGrey = Color(0xFF8F92A1);
const Color kPremiumDivider = Color(0xFFE1E4ED);

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

    return Scaffold(
      backgroundColor: kPremiumBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Account',
          style: TextStyle(
            color: kPremiumDark,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPremiumAccent),
            )
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 80,
                        color: kPremiumGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No user data available',
                        style: TextStyle(
                          color: kPremiumDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header Section with gradient background
                      Container(
                        padding: const EdgeInsets.only(
                            top: 20, bottom: 40, left: 16, right: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              kPremiumBackground,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Profile Image
                            GestureDetector(
                              onTap: () {
                                getData();
                              },
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      kPremiumAccent.withOpacity(0.8),
                                      kPremiumAccent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPremiumAccent.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      image: user?['photo'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(user!['photo']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: user?['photo'] == null
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: kPremiumGrey,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // User Details
                            Text(
                              user?['name'] ?? 'No Name',
                              style: TextStyle(
                                color: kPremiumDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user!['phone'] ?? "No Phone number",
                              style: TextStyle(
                                color: kPremiumGrey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Edit Profile Button
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditPrfileScreen(),
                                  ),
                                );

                                if (result == true) {
                                  setState(() {
                                    _dataUpdated = true;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPremiumAccent,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: kPremiumAccent.withOpacity(0.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Account Options List
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuTile(
                              'My Wishlists',
                              'assets/icons/wishlist.svg',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyWishlistScreen(),
                                  ),
                                );
                              },
                              showDivider: true,
                            ),
                            _buildMenuTile(
                              'Change Password',
                              'assets/icons/key.svg',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdatePasswordScreen(),
                                  ),
                                );
                              },
                              showDivider: true,
                            ),
                            _buildMenuTile(
                              'Delete Your Account',
                              'assets/icons/profile.svg',
                              () {
                                Navigator.of(context)
                                    .pushNamed(AccountRemoveScreen.routeName);
                              },
                              iconColor: Colors.redAccent,
                              textColor: Colors.redAccent,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Additional Options
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuTile(
                              'Log Out',
                              'assets/icons/logout.svg',
                              () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      _buildLogoutDialog(
                                    context,
                                    "Log Out?",
                                    "Are you sure you want to logout?",
                                  ),
                                );
                              },
                              showDivider: true,
                            ),
                            _buildAboutTile(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Version Info
                      Text(
                        "Version: 1.3.0",
                        style: TextStyle(
                          fontSize: 12,
                          color: kPremiumGrey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMenuTile(
    String title,
    String iconPath,
    VoidCallback onTap, {
    bool showDivider = true,
    Color? iconColor,
    Color? textColor,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? kPremiumAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  iconColor ?? kPremiumAccent,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? kPremiumDark,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: kPremiumGrey,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 24,
            endIndent: 24,
            color: kPremiumDivider,
          ),
      ],
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kPremiumAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/about.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              kPremiumAccent,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      title: Text(
        "About",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: kPremiumDark,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: kPremiumGrey,
      ),
    );
  }

  Widget _buildLogoutDialog(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 56,
              color: kPremiumAccent,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kPremiumDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: kPremiumGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: kPremiumDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: kPremiumDivider,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<Auth>(context, listen: false).logout().then(
                          (_) => Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (r) => false));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPremiumAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

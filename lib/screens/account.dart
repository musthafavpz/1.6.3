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
      _dataUpdated = false;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            )
          : user == null
              ? const Center(child: Text('No user data available'))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Profile header with gradient background
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple,
                              Colors.blue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile Image
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: user?['photo'] != null
                                    ? NetworkImage(user!['photo'])
                                    : null,
                                backgroundColor: Colors.white,
                                child: user?['photo'] == null
                                    ? SvgPicture.asset(
                                        'assets/icons/profile_vector.svg',
                                        height: 36,
                                        width: 36,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.grey,
                                          BlendMode.srcIn,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?['name'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?['phone'] ?? "No phone number",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit Profile Button
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditPrfileScreen(),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {
                                    _dataUpdated = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Quick Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                title: "Certificates",
                                icon: Icons.verified_user_outlined,
                                color: Colors.indigo.shade50,
                                iconColor: Colors.indigo,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Certificates feature coming soon")),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                title: "Wishlist",
                                icon: Icons.favorite_border,
                                color: Colors.pink.shade50,
                                iconColor: Colors.pink,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyWishlistScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                title: "Notifications",
                                icon: Icons.notifications_outlined,
                                color: Colors.amber.shade50,
                                iconColor: Colors.amber,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Notifications feature coming soon")),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Account Settings Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'Edit Profile',
                                icon: Icons.person_outline,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditPrfileScreen(),
                                    ),
                                  );
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
                                title: 'Change Password',
                                icon: Icons.lock_outline,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UpdatePasswordScreen(),
                                    ),
                                  );
                                },
                                iconColor: Colors.amber,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // App Settings Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'About App',
                                icon: Icons.info_outline,
                                onTap: () {},
                                iconColor: Colors.grey,
                                showSubtitle: true,
                                subtitle: "Version 1.3.0",
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'Privacy Policy',
                                icon: Icons.privacy_tip_outlined,
                                onTap: () {},
                                iconColor: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Account Management Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'Delete Account',
                                icon: Icons.delete_outline,
                                onTap: () {
                                  Navigator.of(context).pushNamed(AccountRemoveScreen.routeName);
                                },
                                iconColor: Colors.grey,
                                textColor: Colors.red,
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'Log Out',
                                icon: Icons.logout_rounded,
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
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = kDefaultColor,
    Color textColor = Colors.black87,
    bool showSubtitle = false,
    String subtitle = "",
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (showSubtitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        thickness: 0.5,
        height: 0.5,
        color: Colors.grey.withOpacity(0.1),
      ),
    );
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Log Out?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Are you sure you want to logout?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<Auth>(context, listen: false).logout().then(
                            (_) => Navigator.pushNamedAndRemoveUntil(
                                context, '/home', (r) => false));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.white,
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

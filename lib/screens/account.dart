// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

// import 'package:academy_lms_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/auth.dart';
import '../widgets/account_list_tile.dart';
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

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: kBackGroundColor,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: kDefaultColor),
                )
              : user == null
                  ? const Center(child: Text('No user data available'))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            // Reduced top padding
                            const SizedBox(height: 15),
                            ClipOval(
                              child: InkWell(
                                onTap: () {
                                  getData();
                                },
                                child: Container(
                                  // Reduced profile image size
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [kDefaultShadow],
                                    border: Border.all(
                                      color: kDefaultColor.withOpacity(.3),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0), // Reduced padding
                                    child: CircleAvatar(
                                      radius: 50, // Reduced radius
                                      backgroundImage: user?['photo'] != null
                                          ? NetworkImage(user!['photo'])
                                          : null,
                                      backgroundColor: kDefaultColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6), // Reduced padding
                              child: CustomText(
                                text: user?['name'] ?? 'No Name',
                                fontSize: 18, // Reduced font size
                                fontWeight: FontWeight.w500, // Reduced weight
                              ),
                            ),
                            CustomText(
                              text: user!['phone'] ?? "No Phone number",
                              fontSize: 14, // Reduced font size
                              fontWeight: FontWeight.w400, // Reduced weight
                              colors: kGreyLightColor,
                            ),
                            const SizedBox(height: 10), // Reduced spacing
                            SizedBox(
                              height: 60, // Reduced height
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, right: 8), // Reduced padding
                                child: GestureDetector(
                                  child: const AccountListTile(
                                    titleText: 'Edit Profile',
                                    icon: 'assets/icons/profile.svg',
                                    actionType: 'edit',
                                  ),
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
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
                              child: Divider(
                                thickness: 1,
                                color: kGreyLightColor.withOpacity(0.3),
                                height: 3, // Reduced height
                              ),
                            ),
                            SizedBox(
                              height: 60, // Reduced height
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, right: 8), // Reduced padding
                                child: GestureDetector(
                                  child: const AccountListTile(
                                    titleText: 'My Wishlists',
                                    icon: 'assets/icons/wishlist.svg',
                                    actionType: 'wishlists',
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MyWishlistScreen(),
                                        ));
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
                              child: Divider(
                                thickness: 1,
                                color: kGreyLightColor.withOpacity(0.3),
                                height: 3, // Reduced height
                              ),
                            ),
                            SizedBox(
                              height: 60, // Reduced height
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, right: 8), // Reduced padding
                                child: GestureDetector(
                                  child: const AccountListTile(
                                    titleText: 'Change Password',
                                    icon: 'assets/icons/key.svg',
                                    actionType: 'change_password',
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const UpdatePasswordScreen(),
                                        ));
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
                              child: Divider(
                                thickness: 1,
                                color: kGreyLightColor.withOpacity(0.3),
                                height: 3, // Reduced height
                              ),
                            ),
                            SizedBox(
                              height: 60, // Reduced height
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, right: 8), // Reduced padding
                                child: GestureDetector(
                                  child: const AccountListTile(
                                    titleText: 'Delete Your Account',
                                    icon: 'assets/icons/profile.svg',
                                    actionType: 'account_delete',
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        AccountRemoveScreen.routeName);
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
                              child: Divider(
                                thickness: 1,
                                color: kGreyLightColor.withOpacity(0.3),
                                height: 3, // Reduced height
                              ),
                            ),
                            SizedBox(
                              height: 60, // Reduced height
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, right: 8), // Reduced padding
                                child: GestureDetector(
                                  child: const AccountListTile(
                                    titleText: 'Log Out',
                                    icon: 'assets/icons/logout.svg',
                                    actionType: 'logout',
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          buildPopupDialogLogout(
                                        context,
                                        "Log Out?",
                                        "Are you sure, You want to logout?",
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
                              child: Divider(
                                thickness: 1,
                                color: kGreyLightColor.withOpacity(0.3),
                                height: 3, // Reduced height
                              ),
                            ),
                            SizedBox(
                              height: 60, // Reduced height
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8), // Reduced padding
                                  child: ListTile(
                                    leading: Padding(
                                      padding: const EdgeInsets.all(4.0), // Reduced padding
                                      child: SvgPicture.asset(
                                        'assets/icons/about.svg',
                                      ),
                                    ),
                                    subtitle: CustomText(
                                      text: "Version: 1.3.0",
                                      fontSize: 9, // Reduced font size
                                      fontWeight: FontWeight.w400,
                                      colors: kGreyLightColor,
                                    ),
                                    title: CustomText(
                                      text: "About",
                                      fontSize: 16, // Reduced font size
                                      fontWeight: FontWeight.w400, // Reduced weight
                                    ),
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

buildPopupDialogLogout(
  BuildContext context,
  String title,
  String subtitle,
) {
  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0), // Reduced border radius
    ),
    child: Container(
      decoration: BoxDecoration(
          color: kWhiteColor, borderRadius: BorderRadius.circular(16)), // Reduced border radius
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0), // Reduced padding
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20, // Reduced font size
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w500, // Reduced weight
                  ),
                ),
                SizedBox(height: 12), // Reduced spacing
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14, // Reduced font size
                    color: kTextColor,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                bottom: 12.0, left: 12, right: 12, top: 12), // Reduced padding
            child: FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MaterialButton(
                    elevation: 0,
                    color: kPrimaryColor,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12), // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(8), // Reduced border radius
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14, // Reduced font size
                            color: Colors.white,
                            fontWeight: FontWeight.w400, // Reduced weight
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 12, // Reduced spacing
                  ),
                  MaterialButton(
                    elevation: 0,
                    color: kPrimaryColor,
                    onPressed: () {
                      Provider.of<Auth>(context, listen: false).logout().then(
                          (_) => Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (r) => false));
                    },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12), // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(8), // Reduced border radius
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 14, // Reduced font size
                            color: Colors.white,
                            fontWeight: FontWeight.w400, // Reduced weight
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

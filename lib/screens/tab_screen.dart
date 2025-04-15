import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/account.dart';
import 'package:academy_lms_app/screens/cart.dart';
import 'package:academy_lms_app/screens/filter_screen.dart';
import 'package:academy_lms_app/screens/home.dart';
import 'package:academy_lms_app/screens/login.dart';
import 'package:academy_lms_app/screens/my_courses.dart';
import 'package:academy_lms_app/screens/explore.dart'; // Add this import
import 'package:academy_lms_app/widgets/appbar_one.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabsScreen extends StatefulWidget {
  final int pageIndex;

  const TabsScreen({Key? key, this.pageIndex = 0}) : super(key: key);

  @override
  _TabsScreenState createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> with TickerProviderStateMixin {
  int _selectedPageIndex = 0;
  bool isLoggedIn = false;
  bool _isInit = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.pageIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('access_token') ?? '');

    setState(() {
      isLoggedIn = token.isNotEmpty;
      _isInit = false;
    });
  }

  List<Widget> _pages() {
    return isLoggedIn
        ? [
            HomeScreen(),
            ExploreScreen(), // New Explore screen
            MyCoursesScreen(),
            CartScreen(),
            AccountScreen(),
          ]
        : [
            HomeScreen(),
            ExploreScreen(), // New Explore screen
            LoginScreen(),
            LoginScreen(),
            LoginScreen(),
          ];
  }

  void _selectPage(int index) {
    _animationController.reset();
    setState(() {
      _selectedPageIndex = index;
    });
    _animationController.forward();
  }

  Widget _buildTabIcon(String assetName, bool isActive) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Padding(
        key: ValueKey<bool>(isActive),
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(
          assetName,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isActive ? kDefaultColor : kGreyLightColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarOne(logo: 'light_logo.png'),
      body: _isInit
          ? Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: IndexedStack(
                index: _selectedPageIndex,
                children: _pages(),
              ),
            ),
      floatingActionButton: _selectedPageIndex != 3
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const FilterScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              backgroundColor: kWhiteColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: kDefaultColor),
                borderRadius: BorderRadius.circular(100),
              ),
              child: SvgPicture.asset(
                'assets/icons/filter.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  kBlackColor,
                  BlendMode.srcIn,
                ),
              ),
            )
          : null,
      bottomNavigationBar: ConvexAppBar(
        items: [
          TabItem(
            icon: _buildTabIcon('assets/icons/home.svg', _selectedPageIndex == 0),
            activeIcon: _buildTabIcon('assets/icons/home.svg', true),
            title: 'Home',
          ),
          TabItem(
            icon: _buildTabIcon('assets/icons/explore.svg', _selectedPageIndex == 1),
            activeIcon: _buildTabIcon('assets/icons/explore.svg', true),
            title: 'Explore',
          ),
          TabItem(
            icon: _buildTabIcon('assets/icons/my_courses.svg', _selectedPageIndex == 2),
            activeIcon: _buildTabIcon('assets/icons/my_courses.svg', true),
            title: 'Courses',
          ),
          TabItem(
            icon: _buildTabIcon('assets/icons/shopping_bag.svg', _selectedPageIndex == 3),
            activeIcon: _buildTabIcon('assets/icons/shopping_bag.svg', true),
            title: 'Cart',
          ),
          TabItem(
            icon: _buildTabIcon('assets/icons/account.svg', _selectedPageIndex == 4),
            activeIcon: _buildTabIcon('assets/icons/account.svg', true),
            title: 'Account',
          ),
        ],
        backgroundColor: kWhiteColor,
        color: kGreyLightColor,
        activeColor: kDefaultColor,
        elevation: 4,
        curveSize: 100,
        style: TabStyle.reactCircle,
        initialActiveIndex: _selectedPageIndex,
        onTap: _selectPage,
        top: -20,
      ),
    );
  }
}

import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/account.dart';
import 'package:academy_lms_app/screens/cart.dart';
import 'package:academy_lms_app/screens/filter_screen.dart';
import 'package:academy_lms_app/screens/home.dart';
import 'package:academy_lms_app/screens/login.dart';
import 'package:academy_lms_app/screens/my_courses.dart';
import 'package:academy_lms_app/widgets/appbar_one.dart';
import 'package:flutter/material.dart';
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
  
  // Controllers for animations
  late AnimationController _fabAnimationController;
  late AnimationController _pageTransitionController;
  late Animation<double> _fabAnimation;
  late Animation<double> _pageTransition;
  
  // Page controllers
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.pageIndex;
    _checkAuthStatus();
    
    // Setup animation controllers
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    _pageTransition = CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    );
    
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pageTransitionController.dispose();
    _pageController.dispose();
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
        ? [HomeScreen(), MyCoursesScreen(), CartScreen(), AccountScreen()]
        : [HomeScreen(), LoginScreen(), LoginScreen(), LoginScreen()];
  }

  void _selectPage(int index) {
    if (_selectedPageIndex == index) return;
    
    _pageTransitionController.reset();
    _pageTransitionController.forward();
    
    _fabAnimationController.reset();
    if (index != 2) {
      _fabAnimationController.forward();
    }
    
    setState(() {
      _selectedPageIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBody: true, // This ensures content goes behind the bottom nav bar
      appBar: const AppBarOne(logo: 'light_logo.png'),
      body: _isInit
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages(),
            ),
      floatingActionButton: _selectedPageIndex != 2
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => 
                        const FilterScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var begin = const Offset(0.0, 1.0);
                        var end = Offset.zero;
                        var curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                backgroundColor: kWhiteColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1.5, color: kDefaultColor),
                  borderRadius: BorderRadius.circular(30),
                ),
                label: const Text(
                  'Filter',
                  style: TextStyle(
                    color: kBlackColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: SvgPicture.asset(
                  'assets/icons/filter.svg',
                  colorFilter: const ColorFilter.mode(
                    kBlackColor,
                    BlendMode.srcIn,
                  ),
                  height: 20,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: kWhiteColor,
            selectedItemColor: kDefaultColor,
            unselectedItemColor: kGreyLightColor,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedPageIndex,
            onTap: _selectPage,
            elevation: 0,
            items: [
              _buildNavItem('Home', 'assets/icons/home.svg'),
              _buildNavItem('My Courses', 'assets/icons/my_courses.svg'),
              _buildNavItem('My Cart', 'assets/icons/shopping_bag.svg'),
              _buildNavItem('Account', 'assets/icons/account.svg'),
            ],
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(String label, String iconPath) {
    bool isSelected = _pages()[_selectedPageIndex].runtimeType.toString().contains(label.replaceAll(' ', ''));
    
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 40,
        width: isSelected ? 80 : 40,
        decoration: BoxDecoration(
          color: isSelected ? kDefaultColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(
            iconPath,
            colorFilter: ColorFilter.mode(
              isSelected ? kDefaultColor : kGreyLightColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      label: label,
    );
  }
}

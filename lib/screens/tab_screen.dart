import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/account.dart';
import 'package:academy_lms_app/screens/cart.dart';
import 'package:academy_lms_app/screens/explore.dart';
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
  late AnimationController _pageTransitionController;
  late AnimationController _tabAnimationController;
  late Animation<double> _pageTransition;
  late Animation<double> _tabScaleAnimation;
  late Animation<double> _tabFadeAnimation;
  
  // Page controllers
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.pageIndex;
    _checkAuthStatus();
    
    // Setup animation controllers
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _tabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _pageTransition = CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    );
    
    _tabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _tabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _tabFadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _tabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    _tabAnimationController.dispose();
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
        ? [HomeScreen(), ExploreScreen(), MyCoursesScreen(), CartScreen(), AccountScreen()]
        : [HomeScreen(), ExploreScreen(), LoginScreen(), LoginScreen(), LoginScreen()];
  }

  void _selectPage(int index) {
    if (_selectedPageIndex == index) return;
    
    _pageTransitionController.reset();
    _pageTransitionController.forward();
    
    _tabAnimationController.reset();
    _tabAnimationController.forward();
    
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : FadeTransition(
              opacity: _pageTransition,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_pageTransition),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _pages(),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFF6366F1),
              unselectedItemColor: Colors.grey.shade600,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedPageIndex,
              onTap: _selectPage,
              elevation: 0,
              items: [
                _buildNavItem('Home', 'assets/icons/home.svg'),
                _buildNavItem('Explore', 'assets/icons/explore.svg'),
                _buildNavItem('My Courses', 'assets/icons/my_courses.svg'),
                _buildNavItem('My Cart', 'assets/icons/shopping_bag.svg'),
                _buildNavItem('Account', 'assets/icons/account.svg'),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(String label, String iconPath) {
    bool isSelected = _selectedPageIndex == [
      'Home', 
      'Explore', 
      'My Courses', 
      'My Cart', 
      'Account'
    ].indexOf(label);
    
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 40,
        width: isSelected ? 80 : 40,
        decoration: BoxDecoration(
          gradient: isSelected 
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              )
            : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] 
            : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: null, // Handled by bottom navigation bar
            child: ScaleTransition(
              scale: isSelected ? _tabScaleAnimation : const AlwaysStoppedAnimation(1.0),
              child: FadeTransition(
                opacity: isSelected ? _tabFadeAnimation : const AlwaysStoppedAnimation(1.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(
                      isSelected ? Colors.white : Colors.grey.shade600,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      label: label,
      backgroundColor: Colors.transparent,
    );
  }
}

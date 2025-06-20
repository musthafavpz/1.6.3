import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:academy_lms_app/screens/my_course_detail.dart';
import 'package:academy_lms_app/screens/instructor_screen.dart';
import 'package:academy_lms_app/screens/my_courses.dart';
import 'package:academy_lms_app/screens/trending_courses.dart';
import 'package:academy_lms_app/screens/trending_instructors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants.dart';
import '../providers/categories.dart';
import '../providers/courses.dart';
import '../providers/my_courses.dart';
import '../widgets/common_functions.dart';
import 'category_details.dart';
import 'courses_screen.dart';

class BannerItem {
  final String title;
  final String subtitle;
  final String description;
  final String imageAsset;
  final String enrollUrl;
  final String previewVideoId;
  final List<Color> gradientColors;
  final String backgroundType; // 'color' or 'image'
  final String backgroundValue; // color code or image path
  final String enrollButtonText; // Custom text for enroll button
  final String previewButtonText; // Custom text for preview button

  BannerItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageAsset,
    required this.enrollUrl,
    required this.previewVideoId,
    required this.gradientColors,
    this.backgroundType = 'color',
    this.backgroundValue = '#FFFFFF',
    this.enrollButtonText = 'Enroll Now',
    this.previewButtonText = 'Preview',
  });
}

class BannerCarousel extends StatefulWidget {
  final List<BannerItem> bannerItems;
  final Function(BuildContext, String, String) showVideoPreview;
  
  const BannerCarousel({
    Key? key,
    required this.bannerItems,
    required this.showVideoPreview,
  }) : super(key: key);

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.bannerItems.length > 1) {
        final nextPage = (_currentPage + 1) % widget.bannerItems.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }
  
  // Helper method to handle enrollment URL clicks
  void _handleEnrollClick(String enrollUrl) async {
    // Check if enrollUrl is a course ID (number)
    if (int.tryParse(enrollUrl) != null) {
      // Navigate to course detail screen with the ID
      Navigator.of(context).pushNamed(
        CourseDetailScreen.routeName,
        arguments: int.parse(enrollUrl),
      );
    } else {
      // Handle as external URL
      final Uri url = Uri.parse(enrollUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open enrollment link'),
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.bannerItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = widget.bannerItems[index];
                // Get colors based on theme mode
                bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                Color textColor = isDarkMode ? Colors.white : const Color(0xFF333333);
                Color backgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      // For image backgrounds, make the entire banner clickable
                      if (banner.backgroundType == 'image') {
                        _handleEnrollClick(banner.enrollUrl);
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: banner.backgroundType == 'color' 
                            ? isDarkMode 
                                ? Colors.grey[800]
                                : Color(int.tryParse('0xFF${banner.backgroundValue.substring(1)}') ?? 0xFFFFFFFF)
                            : backgroundColor,
                        borderRadius: BorderRadius.circular(18),
                        image: banner.backgroundType == 'image' 
                            ? DecorationImage(
                                image: NetworkImage(banner.backgroundValue),
                                fit: BoxFit.cover,
                                opacity: 1.0, // No opacity for image backgrounds
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Stack(
                          children: [
                            // Only show content for non-image backgrounds
                            if (banner.backgroundType != 'image')
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          banner.title,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          banner.subtitle,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? banner.gradientColors[0].withOpacity(0.85) : banner.gradientColors[0],
                                          ),
                                        ),
                                        const SizedBox(height: 25),
                                        Row(
                                          children: [
                                            // Enroll Now Button
                                            InkWell(
                                              onTap: () => _handleEnrollClick(banner.enrollUrl),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: banner.gradientColors,
                                                  ),
                                                  borderRadius: BorderRadius.circular(30),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: banner.gradientColors[0].withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  banner.enrollButtonText,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Preview Button
                                            InkWell(
                                              onTap: () {
                                                widget.showVideoPreview(context, banner.previewVideoId, banner.title);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: banner.gradientColors[0],
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.play_circle_outline,
                                                      color: banner.gradientColors[0],
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      banner.previewButtonText,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                        color: banner.gradientColors[0],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Image.asset(
                                        banner.imageAsset,
                                        fit: BoxFit.contain,
                                        height: 180,
                                        errorBuilder: (context, error, stackTrace) => SizedBox(
                                          height: 180,
                                          width: double.infinity,
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
                    ),
                  ),
                );
              },
            ),
          ),
          // Enhanced pagination indicators
          if (widget.bannerItems.length > 1)
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.bannerItems.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentPage == index
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFCBD5E1),
                      boxShadow: _currentPage == index 
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ] 
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  var _isInit = true;
  var topCourses = [];
  String? userName;
  Map<String, dynamic>? user;
  bool _isLoading = false;
  
  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // Banner items list - will be populated from API
  List<BannerItem> _bannerItems = [];

  @override
  void initState() {
    super.initState();
    getUserData();
    fetchBanners();
    
    // Initialize animations with smoother curve
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Slightly shorter for better UX
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut, // Use easeOut for smoother appearance
    );
    
    // Don't forward the animation yet - we'll do this after data is loaded
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var userDetails = sharedPreferences.getString("user");

      if (userDetails != null) {
        try {
          setState(() {
            user = jsonDecode(userDetails);
            userName = user?['name'];
          });
        } catch (e) {
          print('Error decoding user details: $e');
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true; // Show loading indicator while fetching data
      });

      // Use optimized batch loading instead of multiple parallel API calls
      _batchLoadData();
    }
    _isInit = false;
    super.didChangeDependencies();
  }
  
  // Optimized batch loading for better performance and error handling
  Future<void> _batchLoadData() async {
    try {
      // Set loading state once at the beginning
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      // Step 1: Load essential data first (categories and top courses)
      await Future.wait([
        Provider.of<Categories>(context, listen: false).fetchCategories(),
        // No need to separately await this - Future.wait does that for us
        Provider.of<Courses>(context, listen: false).fetchTopCourses(),
      ]);
      
      // Step 2: Load secondary data in the background before updating UI
      // This prevents multiple UI refreshes
      List<Future> secondaryRequests = [];
      
      // Add instructors request
      secondaryRequests.add(
        Provider.of<Courses>(context, listen: false).fetchTopInstructors()
          .catchError((error) {
            print('Error loading instructors: $error');
            // Swallow the error to continue
            return null;
          })
      );
      
      // Step 3: Load user-specific data last, only if logged in
      if (user != null) {
        secondaryRequests.add(
          Provider.of<MyCourses>(context, listen: false).fetchMyCourses()
            .catchError((error) {
              print('Error loading my courses: $error');
              // Swallow the error to continue
              return null;
            })
        );
      }
      
      // Wait for all secondary requests to complete before updating UI
      await Future.wait(secondaryRequests);
        
      // Now that all data is loaded, update the UI once
      if (mounted) {
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
          
          // Sort courses by enrollment count (descending order)
          topCourses.sort((a, b) {
            int aEnrollment = _parseEnrollmentCount(a);
            int bEnrollment = _parseEnrollmentCount(b);
            return bEnrollment.compareTo(aEnrollment);
          });
          
          // Set loading to false as all data is loaded
          _isLoading = false;
        });
        
        // Start animation after data is loaded and UI is updated
        _startAnimation();
      }
    } catch (error) {
      print('Error in batch loading data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Start animation even if there was an error
        _startAnimation();
      }
    }
  }

  // Helper method to safely parse enrollment count from various possible fields and types
  int _parseEnrollmentCount(dynamic course) {
    // Try numberOfEnrollment first
    if (course.numberOfEnrollment != null) {
      if (course.numberOfEnrollment is int) {
        return course.numberOfEnrollment;
      } else {
        try {
          return int.parse(course.numberOfEnrollment.toString());
        } catch (e) {
          // Could not parse, continue to next field
        }
      }
    }
    
    // Try totalEnrollment second
    if (course.totalEnrollment != null) {
      if (course.totalEnrollment is int) {
        return course.totalEnrollment;
      } else {
        try {
          return int.parse(course.totalEnrollment.toString());
        } catch (e) {
          // Could not parse, continue to next field
        }
      }
    }
    
    // Try total_reviews as fallback
    if (course.total_reviews != null) {
      if (course.total_reviews is int) {
        return course.total_reviews;
      } else {
        try {
          return int.parse(course.total_reviews.toString());
        } catch (e) {
          // Could not parse
          return 0;
        }
      }
    }
    
    return 0;
  }

  Future<void> refreshList() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      // Step 1: Load all data in parallel with proper error handling
      List<Future> allRequests = [];
      
      // Add essential requests
      allRequests.add(getUserData().catchError((e) {
        print('Error getting user data: $e');
        return null;
      }));
      
      allRequests.add(fetchBanners().catchError((e) {
        print('Error fetching banners: $e');
        return null;
      }));
      
      allRequests.add(Provider.of<Courses>(context, listen: false).fetchTopCourses().catchError((e) {
        print('Error refreshing top courses: $e');
        return null;
      }));
      
      allRequests.add(Provider.of<Courses>(context, listen: false).fetchTopInstructors().catchError((e) {
        print('Error refreshing instructors: $e');
        return null;
      }));
      
      // Only fetch my courses if user is logged in
      if (user != null) {
        allRequests.add(Provider.of<MyCourses>(context, listen: false).fetchMyCourses().catchError((e) {
          print('Error refreshing my courses: $e');
          return null;
        }));
      }

      // Wait for all requests to complete
      await Future.wait(allRequests);
      
      // Update UI once with all loaded data
      if (mounted) {
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
          
          // Sort courses by enrollment count (descending order)
          topCourses.sort((a, b) {
            // Use the helper method to parse enrollment counts
            int aEnrollment = _parseEnrollmentCount(a);
            int bEnrollment = _parseEnrollmentCount(b);
            
            // Sort in descending order (higher enrollment first)
            return bEnrollment.compareTo(aEnrollment);
          });
          
          _isLoading = false;
        });
        
        // Start animation after refresh completes
        _startAnimation();
      }
    } catch (error) {
      print('Error refreshing data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Start animation even if there was an error
        _startAnimation();
        
        // Show a non-intrusive error message using a SnackBar instead of a dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.toString().contains('Authentication')
                        ? 'Your session has expired. Please log in again.'
                        : 'Unable to refresh content. Pull down to try again.',
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: refreshList,
            ),
          ),
        );
      }
    }
  }

  Widget _buildWelcomeMessage() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color accentColor = const Color(0xFF6366F1);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
      ),
            child: Icon(
              user != null ? Icons.person_rounded : Icons.school_rounded,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null ? 'Hello, ${userName?.split(' ')[0] ?? 'there'}' : 'Welcome',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                if (user != null)
                  Text(
                    'Continue your learning journey',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBanner() {
    return _bannerItems.isEmpty
      ? const SizedBox.shrink() // Return empty widget if no banners
      : BannerCarousel(
          bannerItems: _bannerItems,
          showVideoPreview: _showVideoPreview,
        );
  }

  void _showVideoPreview(BuildContext context, String videoId, String courseTitle) {
    // Controller for the WebView
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You could show a loading indicator here
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            // Handle any errors that occur while loading the web page
          },
        ),
      )
      // Load YouTube iframe HTML
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { margin: 0; padding: 0; background-color: #000; }
              iframe { width: 100%; height: 100vh; border: none; }
            </style>
          </head>
          <body>
            <iframe 
              src="https://www.youtube.com/embed/$videoId?autoplay=1&rel=0" 
              frameborder="0" 
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
              allowfullscreen>
            </iframe>
          </body>
        </html>
      ''');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
      width: double.infinity,
            height: 300, // Increased height for better viewing
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Video Title Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
      child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$courseTitle - Preview',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // WebView for embedded YouTube
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: WebViewWidget(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
          Text(
            title,
                style: TextStyle(
              fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onBackground,
                  letterSpacing: 0.2,
            ),
                  ),
              const Spacer(),
          InkWell(
                onTap: () {
                  // Handle navigation based on section title
                  if (title == 'Continue Learning') {
                    // Navigate to My Courses screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyCoursesScreen(),
                      ),
                    );
                  } else if (title == 'Trending Courses') {
                    // Navigate to Trending Courses screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TrendingCoursesScreen(
                          courses: topCourses,
                          title: 'Trending Courses',
                        ),
                      ),
                    );
                  } else if (title == 'Trending Instructors') {
                    // Navigate to Trending Instructors screen
                    final instructors = Provider.of<Courses>(context, listen: false).topInstructors;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TrendingInstructorsScreen(
                          instructors: instructors,
                          title: 'Trending Instructors',
                        ),
                      ),
                    );
                  } else if (title == 'Free Courses') {
                    // Navigate to Free Courses screen
                    final freeCourses = topCourses.where((course) => course.isPaid == 0).toList();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TrendingCoursesScreen(
                          courses: freeCourses,
                          title: 'Free Courses',
                        ),
                      ),
                    );
                  } else if (title == 'Premium Courses') {
                    // Navigate to Premium Courses screen
                    final paidCourses = topCourses.where((course) => course.isPaid == 1).toList();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TrendingCoursesScreen(
                          courses: paidCourses,
                          title: 'Premium Courses',
                        ),
                      ),
                    );
                  } else if (title == 'New Added Courses') {
                    // Navigate to New Added Courses screen
                    // Create a copy of topCourses and sort by ID (descending)
                    final newAddedCourses = List.from(topCourses);
                    newAddedCourses.sort((a, b) => b.id!.compareTo(a.id!));
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TrendingCoursesScreen(
                          courses: newAddedCourses,
                          title: 'New Added Courses',
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
            ),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Color(0xFF6366F1),
                    )
                  ],
                ),
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCourseCard(dynamic course) {
    // Calculate star rating
    final rating = course.average_rating is String 
        ? double.tryParse(course.average_rating) ?? 0.0
        : (course.average_rating ?? 0.0).toDouble();
    
    // Format the price for better display
    final price = course.price.toString();
    final formattedPrice = price == "Free" || price == "0" || price == "\$0" 
        ? "Free"
        : price;
    
    // Check if dark mode is enabled
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color cardBackground = isDarkMode ? Colors.grey[850]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    Color footerBackground = isDarkMode ? Colors.grey[900]! : Theme.of(context).colorScheme.background;
    
    // Build star rating with a more compact design
    Widget buildRatingIndicator() {
      return Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFFFA000),
            size: 16,
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '(${_parseEnrollmentCount(course)})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            CourseDetailScreen.routeName,
            arguments: course.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          height: 280,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail with gradient overlay
              Stack(
                children: [
                  Hero(
                    tag: 'course_${course.id}',
                    child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                    ),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/loading_animated.gif',
                      image: course.thumbnail.toString(),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1).withOpacity(isDarkMode ? 0.8 : 0.7),
                                Color(0xFF8B5CF6).withOpacity(isDarkMode ? 0.8 : 0.7),
                        ],
                      ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.photo_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay for better text readability if needed
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(isDarkMode ? 0.6 : 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Price tag
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? Colors.grey[800]! : Colors.white).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Course info section
              Expanded(
                child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Course Title
                      Text(
                        course.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(isDarkMode ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: const Color(0xFF6366F1),
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                        course.instructor ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                          fontSize: 13,
                                fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                      ),
                    ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Footer with ratings and enrollment
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: footerBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            buildRatingIndicator(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDarkMode ? Colors.grey[800]! : Colors.white).withOpacity(isDarkMode ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: isDarkMode ? Colors.grey[800]! : Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                          Text(
                                    'PREVIEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.grey[800]! : Colors.white,
                          ),
                        ),
                      ],
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
      ),
    );
  }

  Widget _buildContinueLearningCard(dynamic myCourse) {
    // Calculate progress percentage
    double progress = (myCourse.courseCompletion ?? 0).toDouble();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Adapt colors based on theme mode
    Color cardBackground = isDarkMode ? Colors.grey[850]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : const Color(0xFF666666);
    
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          // Navigate to course detail screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                return MyCourseDetailScreen(
                  courseId: myCourse.id,
                  enableDripContent: myCourse.enableDripContent.toString(),
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * .75,
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 140),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side with circular progress
              Container(
                width: 80,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(isDarkMode ? 0.4 : 0.2),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                        // Background circle
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Progress indicator
                        CircularProgressIndicator(
                        value: progress / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 4,
                      ),
                        // Progress text
                    Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                            fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
                ),
              ),
              
              // Course information
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Course title
                      Text(
                        myCourse.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Lesson progress
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFF6366F1),
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${myCourse.totalNumberOfCompletedLessons ?? 0}/${myCourse.totalNumberOfLessons ?? 0} Lessons',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Continue button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_filled_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
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
      ),
    );
  }

  // Build trending instructor card
  Widget _buildTrendingInstructorCard(Map<String, dynamic> instructor) {
    // Generate a unique gradient color based on instructor name
    final List<List<Color>> gradientColors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Purple
      [const Color(0xFF10B981), const Color(0xFF059669)], // Green
      [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Red
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
    ];
    
    // Use a simple hash function to get a consistent color for each instructor
    final int nameHash = instructor['name'].toString().hashCode.abs();
    final colorIndex = nameHash % gradientColors.length;
    final gradientColor = gradientColors[colorIndex];
    
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          // Navigate to instructor profile screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InstructorScreen(
                instructorId: instructor['id']?.toString(),
                instructorName: instructor['name'],
                instructorImage: instructor['image'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                gradientColor[0].withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColor[0].withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: gradientColor[0].withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instructor badge - small icon showing trending
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColor[0].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    "TOP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Circular instructor avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColor,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColor[0].withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: instructor['image'] != null && instructor['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/loading_animated.gif',
                          image: instructor['image'].toString(),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                instructor['name'].toString()[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          instructor['name'].toString()[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              
                    const SizedBox(height: 8),
              
              // Instructor Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  instructor['name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gradientColor[0],
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Student count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gradientColor[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      Icons.person,
                      size: 10,
                      color: gradientColor[0],
                    ),
                    const SizedBox(width: 2),
                        Text(
                      '${instructor['totalEnrollment']}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: gradientColor[0],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build course card with free/paid badge
  Widget _buildCourseCardWithBadge(dynamic course, bool isFreeCourse) {
    // Calculate star rating
    final rating = course.average_rating is String 
        ? double.tryParse(course.average_rating) ?? 0.0
        : (course.average_rating ?? 0.0).toDouble();
    
    // Format the price for better display
    final price = course.price.toString();
    final formattedPrice = price == "Free" || price == "0" || price == "\$0" 
        ? "Free"
        : price;
    
    // Check if dark mode is enabled
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color cardBackground = isDarkMode ? Colors.grey[850]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    Color footerBackground = isDarkMode ? Colors.grey[900]! : Theme.of(context).colorScheme.background;
    
    // Build star rating with a more compact design
    Widget buildRatingIndicator() {
      return Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFFFA000),
            size: 16,
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '(${_parseEnrollmentCount(course)})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            CourseDetailScreen.routeName,
            arguments: course.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          height: 280,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail with gradient overlay
              Stack(
                children: [
                  // Course thumbnail image
                  Hero(
                    tag: 'course_${course.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading_animated.gif',
                        image: course.thumbnail.toString(),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                isFreeCourse 
                                    ? const Color(0xFF10B981).withOpacity(isDarkMode ? 0.8 : 0.7)
                                    : const Color(0xFF6366F1).withOpacity(isDarkMode ? 0.8 : 0.7),
                                isFreeCourse 
                                    ? const Color(0xFF059669).withOpacity(isDarkMode ? 0.8 : 0.7)
                                    : const Color(0xFF8B5CF6).withOpacity(isDarkMode ? 0.8 : 0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.photo_rounded,
                              color: Colors.white,
                            size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Gradient overlay for better text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(isDarkMode ? 0.6 : 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Course type badge (Free/Premium)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFreeCourse
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isFreeCourse ? 'FREE' : 'PREMIUM',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Price tag
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? Colors.grey[800]! : Colors.white).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFreeCourse 
                              ? const Color(0xFF10B981) 
                              : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title
                      Text(
                        course.title.toString(),
                        maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: (isFreeCourse 
                                  ? const Color(0xFF10B981) 
                                  : const Color(0xFF6366F1)).withOpacity(isDarkMode ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: isFreeCourse 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1),
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                        course.instructor ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                                fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Footer with ratings and enrollment
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: footerBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            buildRatingIndicator(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isFreeCourse 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFF6366F1)).withOpacity(isDarkMode ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: isFreeCourse 
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF6366F1),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                          Text(
                                    'PREVIEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isFreeCourse 
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF6366F1),
                          ),
                        ),
                      ],
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
      ),
    );
  }

  // Centralized error handling with user-friendly messages
  Widget _handleError(dynamic error, double height) {
    // Convert technical errors to user-friendly messages
    String userMessage = 'Something went wrong. Please try again.';
    
    if (error != null) {
      if (error.toString().contains('SocketException') || 
          error.toString().contains('Connection refused')) {
        userMessage = 'No internet connection. Please check your network.';
      } else if (error.toString().contains('Authentication')) {
        userMessage = 'Your session has expired. Please log in again.';
      } else if (error.toString().contains('Not Found') || 
                error.toString().contains('404')) {
        userMessage = 'The content you requested is not available right now.';
      } else if (error.toString().contains('timeout')) {
        userMessage = 'The server is taking too long to respond. Please try again later.';
      }
    }
    
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              userMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: refreshList,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch banners from API
  Future<void> fetchBanners() async {
    try {
      final url = Uri.parse('${baseUrl}/api/banners');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['banners'] != null) {
          setState(() {
            _bannerItems = (data['banners'] as List).map((banner) {
              // Parse gradient colors
              List<Color> gradientColors = [
                Color(int.parse('0xFF${banner['gradient_colors'][0].substring(1)}')),
                Color(int.parse('0xFF${banner['gradient_colors'][1].substring(1)}'))
              ];
              
              return BannerItem(
                title: banner['title'],
                subtitle: banner['subtitle'],
                description: banner['description'] ?? '',
                imageAsset: banner['image_path'] ?? 'assets/images/ai_banner.png',
                enrollUrl: banner['enroll_button']['url'] ?? 'https://chat.whatsapp.com/IEekUggTZaI77NHW6ruu10',
                previewVideoId: banner['preview_button']['video_id'] ?? '',
                gradientColors: gradientColors,
                backgroundType: banner['background_type'] ?? 'color',
                backgroundValue: banner['background_value'] ?? '#FFFFFF',
                enrollButtonText: banner['enroll_button']['text'] ?? 'Enroll Now',
                previewButtonText: banner['preview_button']['text'] ?? 'Preview',
              );
            }).toList();
          });
        }
      }
    } catch (error) {
      print('Error fetching banners: $error');
      // If API fails, use default banners
      setState(() {
        _bannerItems = [
          BannerItem(
            title: 'Code the Ledger',
            subtitle: 'From Journal Entries to Neural Networks',
            description: 'Learning AI',
            imageAsset: 'assets/images/ai_banner.png',
            enrollUrl: '1', // Course ID 1 - will navigate to course detail
            previewVideoId: 'npSt5pUexhg',
            gradientColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            backgroundType: 'color',
            backgroundValue: '#FFFFFF',
            enrollButtonText: 'View Course',
            previewButtonText: 'Watch Demo',
          ),
          BannerItem(
            title: 'Flutter Masterclass',
            subtitle: 'Build Beautiful Mobile Apps',
            description: 'Mobile Development',
            imageAsset: 'assets/images/ai_banner.png',
            enrollUrl: 'https://chat.whatsapp.com/IEekUggTZaI77NHW6ruu10', // External URL
            previewVideoId: 'npSt5pUexhg',
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
            backgroundType: 'color',
            backgroundValue: '#FFFFFF',
            enrollButtonText: 'Join Group',
            previewButtonText: 'See Video',
          ),
        ];
      });
    }
  }

  // Method to start animation after data is loaded
  void _startAnimation() {
    if (mounted && _animationController != null) {
      // Reset animation if it was already run
      if (_animationController!.isCompleted) {
        _animationController!.reset();
      }
      _animationController!.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        50;
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Theme.of(context).colorScheme.background,
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: refreshList,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // Top shadow overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              FutureBuilder(
            future: Provider.of<Categories>(context, listen: false).fetchCategories(),
            builder: (ctx, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting || _isLoading) {
                return SizedBox(
                  height: height,
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  ),
                );
                  } else if (dataSnapshot.error != null) {
                  return _handleError(dataSnapshot.error, height);
                } else {
                    // Filter courses by free/paid status
                    final freeCourses = topCourses.where((course) => course.isPaid == 0).toList();
                    final paidCourses = topCourses.where((course) => course.isPaid == 1).toList();
                    
                    // Create a list of new courses (sorted by ID, assuming higher IDs are newer courses)
                    final newAddedCourses = List.from(topCourses);
                    newAddedCourses.sort((a, b) => b.id!.compareTo(a.id!));
                    final latestCourses = newAddedCourses.take(8).toList(); // Take top 8 newest courses
                    
                    return FadeTransition(
                      opacity: _fadeAnimation!,
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          const SizedBox(height: 10),
                      
                      // Welcome Message Section
                      _buildWelcomeMessage(),
                          
                          // Custom Banner with Join Now button
                          _buildCustomBanner(),
                      
                      // Continue Learning Section
                      Consumer<MyCourses>(
                          builder: (ctx, myCourses, _) {
                            // Only show continue learning section if user is logged in
                            if (user == null) {
                              return const SizedBox.shrink();
                            }
                            
                            // Filter out courses with 100% completion
                            final inProgressCourses = myCourses.items
                                .where((course) => (course.courseCompletion ?? 0) < 100)
                                .toList();
                                
                            return inProgressCourses.isNotEmpty
                          ? Column(
                              children: [
                                    _buildSectionTitle('Continue Learning'),
                                Container(
                                      height: 120,
                                      margin: const EdgeInsets.only(bottom: 20),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                        itemCount: inProgressCourses.length,
                                    itemBuilder: (ctx, index) {
                                          return _buildContinueLearningCard(inProgressCourses[index]);
                                    },
                                  ),
                                ),
                              ],
                            )
                              : const SizedBox.shrink();
                          },
                      ),
                      
                      // Trending Courses Section
                        _buildSectionTitle('Trending Courses'),
                      
                      Container(
                          height: 280,
                            margin: const EdgeInsets.only(bottom: 25),
                        child: topCourses.isEmpty
                            ? const Center(child: Text('No trending courses available'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: topCourses.length,
                                itemBuilder: (ctx, index) {
                                  return _buildTrendingCourseCard(topCourses[index]);
                                },
                              ),
                      ),
                        
                        // Trending Instructors Section
                        _buildSectionTitle('Trending Instructors'),
                        
                        Container(
                          height: 140,
                            margin: const EdgeInsets.only(bottom: 25),
                          child: Consumer<Courses>(
                            builder: (ctx, coursesData, _) {
                              final instructors = coursesData.topInstructors;
                              return instructors.isEmpty
                                ? const Center(child: Text('No trending instructors available'))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: instructors.length > 5 ? 5 : instructors.length, // Limit to top 5
                                    itemBuilder: (ctx, index) {
                                      return _buildTrendingInstructorCard(instructors[index]);
                                    },
                                  );
                            },
                          ),
                        ),
                        
                        // Free Courses Section
                        if (freeCourses.isNotEmpty) ...[
                          _buildSectionTitle('Free Courses'),
                          Container(
                            height: 280,
                              margin: const EdgeInsets.only(bottom: 25),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: freeCourses.length,
                              itemBuilder: (ctx, index) {
                                return _buildCourseCardWithBadge(freeCourses[index], true);
                              },
                            ),
                          ),
                        ],
                        
                        // Paid Courses Section
                        if (paidCourses.isNotEmpty) ...[
                          _buildSectionTitle('Premium Courses'),
                          Container(
                            height: 280,
                              margin: const EdgeInsets.only(bottom: 25),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: paidCourses.length,
                              itemBuilder: (ctx, index) {
                                return _buildCourseCardWithBadge(paidCourses[index], false);
                              },
                            ),
                          ),
                        ],
                        
                        // New Added Courses Section
                        if (latestCourses.isNotEmpty) ...[
                          _buildSectionTitle('New Added Courses'),
                          Container(
                            height: 280,
                              margin: const EdgeInsets.only(bottom: 25),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: latestCourses.length,
                              itemBuilder: (ctx, index) {
                                final course = latestCourses[index];
                                return _buildTrendingCourseCard(course);
                              },
                            ),
                          ),
                        ],
                      
                      // Add proper bottom padding for menu tabs
                      const SizedBox(height: 80),
                    ],
                      ),
                  );
              }
            },
            ),
            ],
          ),
        ),
      ),
    );
  }
}


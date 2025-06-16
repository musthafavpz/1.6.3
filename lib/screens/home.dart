import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:academy_lms_app/screens/my_course_detail.dart';
import 'package:academy_lms_app/screens/instructor_screen.dart';
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
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      width: 2,
                      color: banner.gradientColors[0],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: banner.backgroundType == 'color' 
                          ? Color(int.tryParse('0xFF${banner.backgroundValue.substring(1)}') ?? 0xFFFFFFFF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        width: 1,
                        color: banner.gradientColors[1],
                      ),
                      image: banner.backgroundType == 'image' 
                          ? DecorationImage(
                              image: NetworkImage(banner.backgroundValue),
                              fit: BoxFit.cover,
                              opacity: 0.2, // Semi-transparent to ensure text is readable
                            )
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Stack(
                        children: [
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
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        banner.subtitle,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: banner.gradientColors[0],
                                        ),
                                      ),
                                      const SizedBox(height: 25),
                                      Row(
                                        children: [
                                          // Enroll Now Button
                                          InkWell(
                                            onTap: () async {
                                              // Check if enrollUrl is a course ID (number)
                                              if (int.tryParse(banner.enrollUrl) != null) {
                                                // Navigate to course detail screen with the ID
                                                Navigator.of(context).pushNamed(
                                                  CourseDetailScreen.routeName,
                                                  arguments: int.parse(banner.enrollUrl),
                                                );
                                              } else {
                                                // Handle as external URL
                                                final Uri enrollUrl = Uri.parse(banner.enrollUrl);
                                                if (await canLaunchUrl(enrollUrl)) {
                                                  await launchUrl(enrollUrl, mode: LaunchMode.externalApplication);
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
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
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
                );
              },
            ),
          ),
          // Pagination indicators
          if (widget.bannerItems.length > 1)
            Container(
              margin: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.bannerItems.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFCBD5E1),
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
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    
    // Only forward the animation if the widget is still mounted
    if (mounted) {
      _animationController!.forward();
    }
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
      // Step 1: Load essential data first (categories and top courses)
      await Future.wait([
        Provider.of<Categories>(context, listen: false).fetchCategories(),
        Provider.of<Courses>(context, listen: false).fetchTopCourses(),
      ]);
      
      // Immediately update UI with the essential data
          if (mounted) {
            setState(() {
              topCourses = Provider.of<Courses>(context, listen: false).topItems;
              
              // Sort courses by enrollment count (descending order)
              topCourses.sort((a, b) {
                int aEnrollment = _parseEnrollmentCount(a);
                int bEnrollment = _parseEnrollmentCount(b);
                return bEnrollment.compareTo(aEnrollment);
              });
              
          // Still keep loading indicator for secondary data
          _isLoading = false;
            });
          }
        
      // Step 2: Load secondary data in the background
      // These calls won't block the UI from rendering
      await Provider.of<Courses>(context, listen: false).fetchTopInstructors();
        
      // Step 3: Load user-specific data last, only if logged in
        if (user != null) {
        await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
        }
      
    } catch (error) {
      print('Error in batch loading data: $error');
        if (mounted) {
          setState(() {
          _isLoading = false;
          });
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
      
      await getUserData();
      await fetchBanners();
      
      await Provider.of<Courses>(context, listen: false).fetchTopCourses();
      await Provider.of<Courses>(context, listen: false).fetchTopInstructors();
      
      // Only fetch my courses if user is logged in
      if (user != null) {
      await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
      }

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
      }
    } catch (error) {
      print('Error refreshing data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
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

    return;
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Row(
        children: [
          // Avatar/Profile Circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName != null && userName!.isNotEmpty 
                    ? userName![0].toUpperCase() 
                    : "G",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Text content
          Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                      'Hello, ',
                style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Text(
                      userName != null ? '$userName!' : 'Guest!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                      ' 👋',
                style: TextStyle(
                        fontSize: 16,
                ),
              ),
            ],
          ),
                const SizedBox(height: 5),
          Text(
                  user != null 
                  ? 'Ready to continue your learning journey?'
                  : 'Sign in to track your progress and courses.',
            style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6366F1),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
                  fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
                  ),
                ],
              ),
          const SizedBox(height: 5),
          Container(
            width: 35,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(10),
            ),
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
    
    // Build star rating
    List<Widget> buildRatingStars() {
      List<Widget> stars = [];
      for (int i = 1; i <= 5; i++) {
        stars.add(
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFA000),
            size: 14,
          ),
        );
      }
      return stars;
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
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor Name
                      Text(
                        course.instructor ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                      
                      // Star Rating and Enrollment Count
                    Row(
                      children: [
                          ...buildRatingStars(),
                          const SizedBox(width: 5),
                            Text(
                            '(${_parseEnrollmentCount(course)})',
                              style: const TextStyle(
                              fontSize: 12,
                                fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      
                      // Price
                      Text(
                        course.price.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
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
    
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          // Updated navigation to use MyCourseDetailScreen instead of CourseDetailScreen
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
          constraints: const BoxConstraints(minHeight: 140, maxHeight: 160),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Course header with title
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      myCourse.title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress bar and percentage
                      Row(
                        children: [
                          // Progress percentage
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${progress.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // Progress bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Stack(
                                  children: [
                                    // Background bar
                                    Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    // Progress bar
                                    Container(
                                      height: 6,
                                      width: (progress / 100) * (MediaQuery.of(context).size.width * .75 - 80),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Lessons count and continue button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lessons count
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  color: Color(0xFF6366F1),
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${myCourse.totalNumberOfCompletedLessons ?? 0}/${myCourse.totalNumberOfLessons ?? 0} Lessons',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: kGreyLightColor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          // Continue button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'CONTINUE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
    
    // Build star rating
    List<Widget> buildRatingStars() {
      List<Widget> stars = [];
      for (int i = 1; i <= 5; i++) {
        stars.add(
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFA000),
            size: 14,
          ),
        );
      }
      return stars;
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
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF6366F1),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Free/Paid badge removed
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
                            style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor Name
                      Text(
                        course.instructor ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                              fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Star Rating and Enrollment Count
                      Row(
                        children: [
                          ...buildRatingStars(),
                          const SizedBox(width: 5),
                          Text(
                            '(${_parseEnrollmentCount(course)})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 8),
                      
                      // Price
                      Text(
                        course.price.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isFreeCourse ? const Color(0xFF10B981) : const Color(0xFF6366F1),
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        50;
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFFF8F9FA), // Lighter background color
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: refreshList,
        child: FadeTransition(
          opacity: _fadeAnimation!,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder(
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
              } else {
                if (dataSnapshot.error != null) {
                  return _handleError(dataSnapshot.error, height);
                } else {
                    // Filter courses by free/paid status
                    final freeCourses = topCourses.where((course) => course.isPaid == 0).toList();
                    final paidCourses = topCourses.where((course) => course.isPaid == 1).toList();
                    
                    // Create a list of new courses (sorted by ID, assuming higher IDs are newer courses)
                    final newAddedCourses = List.from(topCourses);
                    newAddedCourses.sort((a, b) => b.id!.compareTo(a.id!));
                    final latestCourses = newAddedCourses.take(8).toList(); // Take top 8 newest courses
                    
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
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
                                      height: 160,
                                  margin: const EdgeInsets.only(bottom: 10),
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
                        margin: const EdgeInsets.only(bottom: 10),
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
                          margin: const EdgeInsets.only(bottom: 20),
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
                            margin: const EdgeInsets.only(bottom: 20),
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
                            margin: const EdgeInsets.only(bottom: 20),
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
                            margin: const EdgeInsets.only(bottom: 20),
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
                  );
                }
              }
            },
            ),
          ),
        ),
      ),
    );
  }
}


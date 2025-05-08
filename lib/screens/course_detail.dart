// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:academy_lms_app/models/course_detail.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/widgets/from_vimeo_player.dart';
import 'package:academy_lms_app/widgets/new_youtube_player.dart';
import 'package:academy_lms_app/widgets/no_preview_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/common_functions.dart';
import '../widgets/from_network.dart';
import '../widgets/lesson_list_item.dart';
import '../widgets/tab_view_details.dart';
import '../widgets/util.dart';
import 'filter_screen.dart';
import 'payment_webview.dart';

class CourseDetailScreen extends StatefulWidget {
  static const routeName = '/course-details';
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? selected;
  dynamic token;
  bool _isInit = true;
  bool _isAuth = false;
  bool _isLoading = false;
  bool isLoading = false;
  dynamic courseId;
  CourseDetail? loadedCourseDetail;
  bool _isPreviewVisible = false;
  Widget? _previewWidget;
  var msg = 'Removed from cart';
  var msg2 = 'Added to cart';
  var msg1 = 'please tap again to Buy Now';

  getEnroll(String course_id) async {
    setState(() {
      isLoading = true;
    });
    String url = "$baseUrl/api/free_course_enroll/$course_id";
    var navigator = Navigator.of(context);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    token = sharedPreferences.getString("access_token");
    var response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    print(url);
    print(token);

    final data = jsonDecode(response.body);
    // print(data['message']);
    // print(response.body);
    if (response.statusCode == 200) {
      navigator.pushReplacement(
        MaterialPageRoute(
            builder: (context) => TabsScreen(
                  pageIndex: 1,
                )),
      );
      setState(() {
        isLoading = false;
      });
    } else {
      Fluttertoast.showToast(msg: data['message']);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    if (_isInit) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        token = (prefs.getString('access_token') ?? '');
      });
      setState(() {
        _isLoading = true;
        // _authToken = Provider.of<Auth>(context, listen: false).token;
        if (token != null && token.isNotEmpty) {
          _isAuth = true;
        } else {
          _isAuth = false;
        }
      });

      courseId = ModalRoute.of(context)!.settings.arguments as int;

      Provider.of<Courses>(context, listen: false)
          .fetchCourseDetailById(courseId)
          .then((_) {
        Provider.of<Courses>(context, listen: false).getCourseDetail;

        // Provider.of<Courses>(context, listen: false).findById(courseId);

        setState(() {
          _isLoading = false;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _showVideoPreview(String? previewUrl) {
    if (previewUrl == null) {
      setState(() {
        _previewWidget = NoPreviewVideo();
        _isPreviewVisible = true;
      });
      return;
    }

    final isYouTube = previewUrl.contains("youtube.com") || previewUrl.contains("youtu.be");
    final isVimeo = previewUrl.contains("vimeo.com");
    final isDrive = previewUrl.contains("drive.google.com");
    final isMp4 = RegExp(r"\.mp4(\?|$)").hasMatch(previewUrl);
    final isWebm = RegExp(r"\.webm(\?|$)").hasMatch(previewUrl);
    final isOgg = RegExp(r"\.ogg(\?|$)").hasMatch(previewUrl);

    Widget previewWidget;

    if (isYouTube) {
      previewWidget = YoutubeVideoPlayerFlutter(
        courseId: courseId,
        videoUrl: previewUrl,
      );
    } else if (isDrive) {
      final RegExp regExp = RegExp(r'[-\w]{25,}');
      final Match? match = regExp.firstMatch(previewUrl);
      String url = 'https://drive.google.com/uc?export=download&id=${match!.group(0)}';
      previewWidget = PlayVideoFromNetwork(
        courseId: courseId,
        videoUrl: url,
      );
    } else if (isVimeo) {
      String vimeoVideoId = previewUrl.split('/').last;
      previewWidget = FromVimeoPlayer(
        courseId: courseId,
        vimeoVideoId: vimeoVideoId,
      );
    } else if (isMp4 || isOgg || isWebm) {
      previewWidget = PlayVideoFromNetwork(
        courseId: courseId,
        videoUrl: previewUrl,
      );
    } else {
      previewWidget = NoPreviewVideo();
    }

    setState(() {
      _previewWidget = previewWidget;
      _isPreviewVisible = true;
    });
  }

  void _hideVideoPreview() {
    setState(() {
      _isPreviewVisible = false;
      _previewWidget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Course Details',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDefaultColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            )
          : Consumer<Courses>(
              builder: (context, courses, child) {
                final loadedCourseDetails = courses.getCourseDetail;
                return Stack(
                  children: [
                    // Main content
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Course Banner and Video Preview
                                Stack(
                                  children: [
                                    // Course Thumbnail
                                    GestureDetector(
                                      onTap: () {
                                        _showVideoPreview(loadedCourseDetails.preview);
                                      },
                                      child: Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: NetworkImage(
                                              loadedCourseDetails.thumbnail.toString(),
                                            ),
                                          ),
                                        ),
                                        foregroundDecoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.5),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: kDefaultColor,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Course Info
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(top: 180),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loadedCourseDetails.title.toString(),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                color: kGreyLightColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                loadedCourseDetails.instructor.toString(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: kGreyLightColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _buildInfoChip(
                                                icon: Icons.people,
                                                text: "${loadedCourseDetails.numberOfEnrollment} Students",
                                              ),
                                              const SizedBox(width: 8),
                                              _buildInfoChip(
                                                icon: Icons.play_lesson,
                                                text: "${loadedCourseDetails.totalNumberOfLessons} Lessons",
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Tabs
                                Container(
                                  color: Colors.white,
                                  child: TabBar(
                                    controller: _tabController,
                                    indicatorColor: kDefaultColor,
                                    indicatorWeight: 3,
                                    labelColor: kDefaultColor,
                                    unselectedLabelColor: kGreyLightColor,
                                    tabs: const [
                                      Tab(text: 'About'),
                                      Tab(text: 'Lessons'),
                                    ],
                                  ),
                                ),
                                
                                // Tab Content
                                Container(
                                  color: Colors.white,
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // About Tab
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildSectionTitle("Description"),
                                            TabViewDetails(description: loadedCourseDetails.description),
                                            const SizedBox(height: 16),
                                            
                                            if (loadedCourseDetails.requirements != null && 
                                                loadedCourseDetails.requirements!.isNotEmpty)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildSectionTitle("Requirements"),
                                                  TabViewDetails(description: loadedCourseDetails.requirements),
                                                  const SizedBox(height: 16),
                                                ],
                                              ),
                                              
                                            if (loadedCourseDetails.outcomes != null && 
                                                loadedCourseDetails.outcomes!.isNotEmpty)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildSectionTitle("What You'll Learn"),
                                                  TabViewDetails(description: loadedCourseDetails.outcomes),
                                                  const SizedBox(height: 16),
                                                ],
                                              ),
                                              
                                            const SizedBox(height: 100), // Bottom padding for action buttons
                                          ],
                                        ),
                                      ),
                                      
                                      // Lessons Tab
                                      loadedCourseDetails.mSection != null
                                          ? ListView.builder(
                                              padding: const EdgeInsets.only(bottom: 100),
                                              itemCount: loadedCourseDetails.mSection!.length,
                                              itemBuilder: (ctx, index) {
                                                return LessonListItem.fromSection(loadedCourseDetails.mSection![index]);
                                              },
                                            )
                                          : const Center(child: Text('No lessons available'))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Video Preview Overlay
                    if (_isPreviewVisible && _previewWidget != null)
                      Container(
                        color: Colors.black.withOpacity(0.9),
                        child: Stack(
                          children: [
                            Center(child: _previewWidget!),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: GestureDetector(
                                onTap: _hideVideoPreview,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Bottom Action Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                        child: SafeArea(
                          child: Row(
                            children: [
                              // Price information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Price",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kGreyLightColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loadedCourseDetails.price.toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: loadedCourseDetails.isPaid == 1 ? kDefaultColor : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Main action button (buy, enroll, etc.)
                              Expanded(
                                flex: 2,
                                child: _buildMainActionButton(loadedCourseDetails),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Loading overlay
                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kDefaultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kDefaultColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: kDefaultColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainActionButton(CourseDetail courseDetails) {
    if (courseDetails.isPurchased!) {
      // Already purchased course
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => TabsScreen(pageIndex: 1)),
          );
        },
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Start Learning'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    } else if (courseDetails.isPaid == 1) {
      // Paid course - not purchased yet
      return Row(
        children: [
          // Add to cart button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final authToken = (prefs.getString('access_token') ?? '');
                if (authToken.isNotEmpty) {
                  Provider.of<Courses>(context, listen: false)
                      .toggleCart(courseDetails.courseId!, false)
                      .then((_) {
                    if (courseDetails.is_cart!) {
                      CommonFunctions.showSuccessToast("Removed from cart");
                    } else {
                      CommonFunctions.showSuccessToast("Added to cart");
                    }
                  });
                } else {
                  CommonFunctions.showSuccessToast('Please login first');
                }
              },
              icon: Icon(
                courseDetails.is_cart! ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                size: 18,
              ),
              label: Text(
                courseDetails.is_cart! ? "In Cart" : "Add to Cart",
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kDefaultColor,
                side: const BorderSide(color: kDefaultColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Buy now button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final authToken = (prefs.getString('access_token') ?? '');
                if (authToken.isNotEmpty) {
                  final emailPre = prefs.getString('email');
                  final passwordPre = prefs.getString('password');
                  var email = emailPre;
                  var password = passwordPre;
                  
                  DateTime currentDateTime = DateTime.now();
                  int currentTimestamp = (currentDateTime.millisecondsSinceEpoch / 1000).floor();
                  
                  String authToken = 'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
                  final url = '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem';
                  
                  // Use PaymentWebView instead of external browser
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PaymentWebView(url: url),
                    ),
                  );
                  
                  CommonFunctions.showSuccessToast(msg1);
                  if (!courseDetails.is_cart!) {
                    Provider.of<Courses>(context, listen: false).toggleCart(courseDetails.courseId!, false);
                  }
                } else {
                  CommonFunctions.showWarningToast('Please login first');
                }
              },
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Buy Now', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDefaultColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    } else {
      // Free course
      return ElevatedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final authToken = (prefs.getString('access_token') ?? '');
          if (authToken.isNotEmpty) {
            await getEnroll(courseDetails.courseId.toString());
            CommonFunctions.showSuccessToast('Course Successfully Enrolled');
          } else {
            CommonFunctions.showWarningToast('Please login first');
          }
        },
        icon: const Icon(Icons.school),
        label: const Text('Enroll Now - FREE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kDefaultColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    }
  }
}

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
    _tabController = TabController(length: 3, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: kDefaultColor),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share, color: kDefaultColor),
            ),
            onPressed: () {
              Consumer<Courses>(
                builder: (context, courses, child) {
                  final loadedCourseDetails = courses.getCourseDetail;
                  Share.share(loadedCourseDetails.shareableLink.toString(),
                      subject: loadedCourseDetails.title.toString());
                  return const SizedBox();
                },
              );
            },
          ),
        ],
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
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course banner with play button
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Banner image
                              Container(
                                height: 250,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                  ),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                      loadedCourseDetails.thumbnail.toString(),
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Play button
                              GestureDetector(
                                onTap: () {
                                  if (loadedCourseDetails.preview != null) {
                                    final previewUrl = loadedCourseDetails.preview!;
                                    final isYouTube = previewUrl.contains("youtube.com") || previewUrl.contains("youtu.be");
                                    final isVimeo = previewUrl.contains("vimeo.com");
                                    final isDrive = previewUrl.contains("drive.google.com");
                                    final isMp4 = RegExp(r"\.mp4(\?|$)").hasMatch(previewUrl);
                                    final isWebm = RegExp(r"\.webm(\?|$)").hasMatch(previewUrl);
                                    final isOgg = RegExp(r"\.ogg(\?|$)").hasMatch(previewUrl);

                                    if (isYouTube) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => YoutubeVideoPlayerFlutter(
                                            courseId: loadedCourseDetails.courseId!,
                                            videoUrl: previewUrl,
                                          ),
                                        ),
                                      );
                                    } else if (isDrive) {
                                      final RegExp regExp = RegExp(r'[-\w]{25,}');
                                      final Match? match = regExp.firstMatch(loadedCourseDetails.preview.toString());
                                      String url = 'https://drive.google.com/uc?export=download&id=${match!.group(0)}';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => PlayVideoFromNetwork(
                                                courseId: loadedCourseDetails.courseId!,
                                                videoUrl: url)),
                                      );
                                    } else if (isVimeo) {
                                      String vimeoVideoId = loadedCourseDetails.preview!.split('/').last;
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FromVimeoPlayer(
                                                courseId: loadedCourseDetails.courseId!,
                                                vimeoVideoId: vimeoVideoId),
                                          ));
                                    } else if (isMp4 || isOgg || isWebm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlayVideoFromNetwork(
                                            courseId: loadedCourseDetails.courseId!,
                                            videoUrl: previewUrl,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NoPreviewVideo(),
                                        ),
                                      );
                                    }
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NoPreviewVideo(),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
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
                              
                              // Wishlist button
                              Positioned(
                                top: 90,
                                right: 15,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      loadedCourseDetails.isWishlisted!
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 20,
                                      color: loadedCourseDetails.isWishlisted!
                                          ? Colors.red
                                          : kGreyLightColor,
                                    ),
                                    onPressed: () {
                                      if (_isAuth) {
                                        var msg = loadedCourseDetails.isWishlisted;
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              buildPopupDialogWishList(
                                                  context,
                                                  loadedCourseDetails.isWishlisted,
                                                  loadedCourseDetails.courseId,
                                                  msg),
                                        );
                                      } else {
                                        CommonFunctions.showSuccessToast('Please login first');
                                      }
                                    },
                                  ),
                                ),
                              ),
                              
                              // Course title and details positioned at bottom of image
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loadedCourseDetails.title.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, color: Colors.white70, size: 16),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              loadedCourseDetails.instructor.toString(),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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

                          // Course stats
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  icon: Icons.star,
                                  value: loadedCourseDetails.average_rating.toString(),
                                  label: "Rating",
                                  iconColor: Colors.amber,
                                ),
                                _buildStatItem(
                                  icon: Icons.people,
                                  value: loadedCourseDetails.numberOfEnrollment.toString(),
                                  label: "Students",
                                  iconColor: Colors.blue,
                                ),
                                _buildStatItem(
                                  icon: Icons.play_lesson,
                                  value: loadedCourseDetails.totalNumberOfLessons.toString(),
                                  label: "Lessons",
                                  iconColor: Colors.green,
                                ),
                              ],
                            ),
                          ),

                          // Tab bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: kDefaultColor,
                                indicatorWeight: 3,
                                indicatorSize: TabBarIndicatorSize.label,
                                labelColor: kDefaultColor,
                                unselectedLabelColor: kGreyLightColor,
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                tabs: const [
                                  Tab(text: 'About'),
                                  Tab(text: 'Lessons'),
                                  Tab(text: 'Reviews'),
                                ],
                              ),
                            ),
                          ),

                          // Tab content
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // About tab
                                TabViewDetails(description: loadedCourseDetails.description),
                                
                                // Lessons tab
                                loadedCourseDetails.mSection != null
                                    ? ListView.builder(
                                        itemCount: loadedCourseDetails.mSection!.length,
                                        itemBuilder: (ctx, index) {
                                          return LessonListItem.fromSection(loadedCourseDetails.mSection![index]);
                                        },
                                      )
                                    : const Center(child: Text('No lessons available')),
                                
                                // Reviews tab
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(15),
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(15),
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
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  loadedCourseDetails.average_rating ?? "0.0",
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: kDefaultColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                                        Icon(Icons.star_half, color: Colors.amber, size: 16),
                                                      ],
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      "Based on reviews",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: kGreyLightColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Additional review content
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          "Student Reviews",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Placeholder for review items
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text("No reviews available"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Add bottom spacing to prevent overlap with button bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    
                    // Floating action buttons at bottom
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
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: kGreyLightColor,
          ),
        ),
      ],
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

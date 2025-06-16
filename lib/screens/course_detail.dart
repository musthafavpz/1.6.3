// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:academy_lms_app/models/course_detail.dart';
import 'package:academy_lms_app/screens/ai_assistant.dart';
import 'package:academy_lms_app/screens/instructor_screen.dart';
import 'package:academy_lms_app/screens/my_courses.dart';
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
import 'package:flutter/rendering.dart';

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

  // Helper widget to create stat items for course overview
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
                    Text(
          title,
                                  style: TextStyle(
            fontSize: 18,
                        fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
            color: Colors.grey.shade600,
                      ),
                    ),
            ],
        );
    }

  @override
  Widget build(BuildContext context) {
    // final courseId = ModalRoute.of(context)!.settings.arguments as int;
    // final loadedCourse = Provider.of<Courses>(
    //   context,
    //   listen: false,
    // ).findById(courseId);
    // final loadedCourseDetail = Provider.of<Courses>(
    //   context,
    //   listen: false,
    // ).getCourseDetail;

    customNavBar() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kDefaultColor),
              )
            : Consumer<Courses>(builder: (context, courses, child) {
                final loadedCourseDetails = courses.getCourseDetail;

                return SizedBox(
                  height: 65,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.transparent),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Text(loadedCourseDetail.isPurchased.toString()),
                                IconButton(
                                    icon: SvgPicture.asset(
                                      'assets/icons/account.svg',
                                      colorFilter: const ColorFilter.mode(
                                          kGreyLightColor, BlendMode.srcIn),
                                    ),
                                    onPressed: () {
                                      // Handle account icon tap
                                      // You can navigate to the account page or show a user menu here
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const TabsScreen(
                                                    pageIndex: 3,
                                                  )));
                                    },
                                    visualDensity: const VisualDensity(
                                        horizontal: -4, vertical: -4)),
                                const Text(
                                  'Account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: kGreyLightColor,
                                  ),
                                ),
                              ],
                            ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 15),
                        child: VerticalDivider(
                          thickness: 1.0, // Adjust the thickness of the divider
                          color:
                              kGreyLightColor, // Adjust the color of the divider
                        ),
                      ),
                      loadedCourseDetails.isPurchased!
                          ? SizedBox()
                          : loadedCourseDetails.isPaid == 1
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: MaterialButton(
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    onPressed: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final authToken =
                                          (prefs.getString('access_token') ??
                                              '');
                                      if (authToken.isNotEmpty) {
                                        if (loadedCourseDetails.isPaid == 1) {
                                          // if (msg1 ==
                                          //     'please tap again to Buy Now') {

                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          final emailPre =
                                              prefs.getString('email');
                                          final passwordPre =
                                              prefs.getString('password');
                                          var email = emailPre;
                                          var password = passwordPre;
                                          // print(email);
                                          // print(password);
                                          // var email = "student@example.com";
                                          // var password = "12345678";
                                          DateTime currentDateTime =
                                              DateTime.now();
                                          int currentTimestamp = (currentDateTime
                                                      .millisecondsSinceEpoch /
                                                  1000)
                                              .floor();

                                          String authToken =
                                              'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
                                          // print(authToken);
                                          final url =
                                              '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem';
                                          // print(url);
                                          // _launchURL(url);

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PaymentWebView(url: url),
                                            ),
                                          );
                                          
                                          CommonFunctions.showSuccessToast('Processing payment...');
                                          if (!loadedCourseDetails.is_cart!) {
                                            Provider.of<Courses>(context, listen: false)
                                                .toggleCart(loadedCourseDetails.courseId!, false);
                                          }
                                          
                                        }

                                        // CommonFunctions.showSuccessToast('Failed to connect');
                                      } else {
                                        CommonFunctions.showWarningToast(
                                            'Please login first');
                                      }
                                    },
                                    color: kDefaultColor,
                                    height: 45,
                                    minWidth: 111,
                                    textColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13.0),
                                      side: const BorderSide(
                                          color: kDefaultColor),
                                    ),
                                    child: const Text(
                                      'Buy Now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: 111,
                                ),
                      loadedCourseDetails.isPurchased!
                          ? Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: MaterialButton(
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                onPressed: () async {
                                  // await getEnroll(loadedCourse.id.toString());
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final authToken =
                                      (prefs.getString('access_token') ?? '');
                                  if (authToken.isNotEmpty) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) => const MyCoursesScreen(),
                                      ),
                                    );
                                  } else {
                                    CommonFunctions.showWarningToast(
                                        'Please login first');
                                  }
                                },
                                color: kGreenPurchaseColor,
                                height: 45,
                                minWidth: 111,
                                textColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13.0),
                                  side: const BorderSide(
                                      color: kGreenPurchaseColor),
                                ),
                                child: const Text(
                                  'Purchased',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : loadedCourseDetails.isPaid == 1
                              ? MaterialButton(
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  onPressed: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final authToken =
                                        (prefs.getString('access_token') ?? '');

                                    if (authToken.isNotEmpty) {
                                      if (loadedCourseDetails.isPaid == 1) {
                                        // Call the provider method to toggle the cart state
                                        Provider.of<Courses>(context,
                                                listen: false)
                                            .toggleCart(
                                                loadedCourseDetails.courseId!,
                                                false);

                                        // Show toast based on current state
                                        if (loadedCourseDetails.is_cart!) {
                                          CommonFunctions.showSuccessToast(
                                              "Removed from cart");
    } else {
                                          CommonFunctions.showSuccessToast(
                                              "Added to cart");
                                        }
                                      } else {
                                        CommonFunctions.showWarningToast(
                                            "It's a free course! Click on Buy Now");
                                      }
                                    } else {
                                      CommonFunctions.showSuccessToast(
                                          'Please login first');
                                    }
                                  },
                                  color: loadedCourseDetails.is_cart!
                                      ? kDefaultColor
                                      : kWhiteColor,
                                  height: 45,
                                  minWidth: 111,
                                  textColor:
                                      const Color.fromARGB(255, 102, 76, 76),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13.0),
                                    side:
                                        const BorderSide(color: kDefaultColor),
                                  ),
                                  child: Text(
                                    loadedCourseDetails.is_cart!
                                        ? "Added to cart"
                                        : 'Add to Cart',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: loadedCourseDetails.is_cart!
                                          ? kWhiteColor
                                          : kDefaultColor,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: MaterialButton(
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    onPressed: () async {
                                      // await getEnroll(loadedCourse.id.toString());
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final authToken =
                                          (prefs.getString('access_token') ??
                                              '');
                                      if (authToken.isNotEmpty) {
                                        if (loadedCourseDetails.isPaid == 0) {
                                          await getEnroll(loadedCourseDetails
                                              .courseId
                                              .toString());
                                          // print(loadedCourse.id.toString());
                                          CommonFunctions.showSuccessToast(
                                              'Course Succesfully Enrolled');
                                        }
                                        // CommonFunctions.showSuccessToast(
                                        //     'Failed to connect');
                                      } else {
                                        CommonFunctions.showWarningToast(
                                            'Please login first');
                                      }
                                    },
                                    color: kDefaultColor,
                                    height: 45,
                                    minWidth: 111,
                                    textColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13.0),
                                      side: const BorderSide(
                                          color: kDefaultColor),
                                    ),
                                    child: Text(
                                      'Enroll Now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                    ],
                  ),
                );
              }),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackGroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: kDefaultColor,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Course Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          // AI Assistant icon removed from here
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height * 1,
        color: const Color(0xFFF8F9FA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kDefaultColor),
              )
            : Consumer<Courses>(builder: (context, courses, child) {
                CourseDetail loadedCourseDetails;
                
                try {
                  loadedCourseDetails = courses.getCourseDetail;
                  if (loadedCourseDetails == null) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading course details...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  loadedCourseDetail = loadedCourseDetails;
                } catch (e) {
                  return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                        Icon(
                          Icons.error_outline,
                          color: Color(0xFFEF4444),
                          size: 60,
                        ),
                        SizedBox(height: 16),
                    Text(
                          'Failed to load course details',
                          style: TextStyle(
                            fontSize: 18,
                        fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                      style: TextStyle(
                        fontSize: 16,
                            color: Color(0xFF6B7280),
                      ),
                    ),
            ],
          ),
        );
                }
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Text(loadedCourseDetail.isPurchased.toString()),
                            Stack(
                          fit: StackFit.loose,
                              alignment: Alignment.center,
                          clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: double.infinity,
                              height: MediaQuery.of(context).size.width * 0.5625, // 16:9 aspect ratio
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        loadedCourseDetails.thumbnail.toString(),
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                              ),
                            ),
                            ClipOval(
                              child: InkWell(
                                  onTap: () {
                                  if (loadedCourseDetails.preview != null) {
                                    final previewUrl = loadedCourseDetails.preview!;
                                    print(previewUrl);

                                    final isYouTube = previewUrl.contains("youtube.com") ||
                                        previewUrl.contains("youtu.be");
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
                                            videoUrl: url,
                                          ),
                                        ),
                                      );
                                    } else if (isVimeo) {
                                      String vimeoVideoId = loadedCourseDetails.preview!.split('/').last;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FromVimeoPlayer(
                                            courseId: loadedCourseDetails.courseId!,
                                            vimeoVideoId: vimeoVideoId,
                                          ),
                                        ),
                                      );
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
                                    print("Preview URL is null");
                                  }
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [kDefaultShadow],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Image.asset(
                                      'assets/images/play.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                                                ),
                                              ],
                                            ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 25.0, left: 5, right: 5),
                          child: Row(
                                                  children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                                      loadedCourseDetails.title.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                              ),
                            ],
                          ),
                        ),
                                                // Instructor information
                                                if (loadedCourseDetails.instructor != null && 
                                                   loadedCourseDetails.instructor!.isNotEmpty)
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => InstructorScreen(
                                                            instructorName: loadedCourseDetails.instructor,
                                                            instructorImage: loadedCourseDetails.instructorImage,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 15),
                                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                                    decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: const Color(0xFF6366F1).withOpacity(0.2),
                                                        width: 1,
                                                      ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF6366F1).withOpacity(0.1),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: loadedCourseDetails.instructorImage != null &&
                                                                loadedCourseDetails.instructorImage!.isNotEmpty
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(20),
                                                                child: Image.network(
                                                                  loadedCourseDetails.instructorImage!,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return const Icon(
                                                                      Icons.person,
                                                                      color: Color(0xFF6366F1),
                                                                      size: 24,
                                                                    );
                                                                  },
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons.person,
                                                                color: Color(0xFF6366F1),
                                                                size: 24,
                                                              ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                "Instructor",
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Color(0xFF6366F1),
                                                                ),
                                                              ),
                                                        Text(
                                                                loadedCourseDetails.instructor!,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                                                  color: Color(0xFF374151),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.chevron_right,
                                                          color: Color(0xFF6B7280),
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  ),
                                                    // Course Overview Section
                                                    Container(
                                                      margin: const EdgeInsets.only(bottom: 20),
                                                      padding: const EdgeInsets.all(15),
                                                      decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                            children: [
                                                              // Total lessons
                                                              Expanded(
                                                                child: _buildStatItem(
                                                                  icon: Icons.video_library_outlined,
                                                                  title: '${loadedCourseDetails.totalNumberOfLessons ?? loadedCourseDetails.mSection?.length ?? 0}',
                                                                  subtitle: 'Lessons',
                                      color: const Color(0xFF6366F1),
                                                                ),
                                                              ),
                                                              
                                                              // Total enrollments
                                                              Expanded(
                                                                child: _buildStatItem(
                                                                  icon: Icons.people_outline,
                                                                  title: '${loadedCourseDetails.numberOfEnrollment ?? loadedCourseDetails.totalEnrollment ?? 0}',
                                                                  subtitle: 'Students',
                                      color: const Color(0xFF6366F1),
                                                                ),
                                                              ),
                                                              
                                                              // Rating if available
                                                              Expanded(
                                                                child: _buildStatItem(
                                                                  icon: Icons.star_outline,
                                                                  title: () {
                                                                    if (loadedCourseDetails.average_rating == null) {
                                                                      return 'N/A';
                                                                    }
                                                                    
                                                                    if (loadedCourseDetails.average_rating is double) {
                                                                      return loadedCourseDetails.average_rating.toStringAsFixed(1);
                                                                    } else if (loadedCourseDetails.average_rating is int) {
                                                                      return loadedCourseDetails.average_rating.toString();
                                                                    } else {
                                                                      try {
                                                                        final value = double.parse(loadedCourseDetails.average_rating.toString());
                                                                        return value.toStringAsFixed(1);
                                                                      } catch (e) {
                                                                        return loadedCourseDetails.average_rating.toString();
                                                                      }
                                                                    }
                                                                  }(),
                                                                  subtitle: 'Rating',
                                      color: const Color(0xFF6366F1),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                        SingleChildScrollView(
                          child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                                                        Container(
                                                          decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                      color: kBackButtonBorderColor
                                          .withOpacity(0.07),
                                      blurRadius: 15,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Column(
                                                        children: [
                                      SizedBox(
                                                            width: double.infinity,
                                        child: TabBar(
                                          controller: _tabController,
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          indicator: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF6366F1),
                                                Color(0xFF8B5CF6),
                                              ],
                                            ),
                                          ),
                                          unselectedLabelStyle: const TextStyle(
                                                                                    fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                                                                    color: Color(0xFF6B7280),
                                                                                  ),
                                          labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                          dividerHeight: 0,
                                          tabs: const <Widget>[
                                            Tab(
                                              child: Text(
                                                "Includes",
                                                                            style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                                              fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Text(
                                                "Outcomes",
                                                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Text(
                                                "Required",
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                                                ),
                                                                              ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                      Container(
                                        width: double.infinity,
                                        height: 215,
                                        padding: const EdgeInsets.only(
                                            right: 10,
                                            left: 10,
                                            top: 0,
                                            bottom: 10),
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                            TabViewDetails(
                                              titleText: 'What is Included',
                                              listText: loadedCourseDetails
                                                  .courseIncludes,
                                            ),
                                            TabViewDetails(
                                              titleText: 'What you will learn',
                                              listText: loadedCourseDetails
                                                  .courseOutcomes,
                                            ),
                                            TabViewDetails(
                                              titleText: 'Course Requirements',
                                              listText: loadedCourseDetails
                                                  .courseRequirements,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                            ),
                                                ),
                                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 10),
                                child: Text(
                                  'Course curriculum',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                                                    ListView.builder(
                                                      key: Key('builder ${selected.toString()}'),
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: loadedCourseDetails.mSection!.length,
                                                      itemBuilder: (ctx, index) {
                                  final section =
                                      loadedCourseDetails.mSection![index];
                                                        return Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              boxShadow: [
                                                                BoxShadow(
                                            color: kBackButtonBorderColor
                                                .withOpacity(0.05),
                                            blurRadius: 25,
                                            offset: const Offset(0, 0),
                                                            ),
                                                          ],
                                                        ),
                                      child: Card(
                                        elevation: 0.0,
                                        child: ExpansionTile(
                                          key: Key(index.toString()),
                                          initiallyExpanded: index == selected,
                                          onExpansionChanged: ((newState) {
                                            if (newState) {
                                                                    setState(() {
                                                                    selected = index;
                                              });
                                            } else {
                                              setState(() {
                                                selected = -1;
                                              });
                                            }
                                          }),
                                          iconColor: kDefaultColor,
                                          collapsedIconColor: kSelectItemColor,
                                          trailing: Container(
                                            width: 32,
                                            height: 32,
                                                                decoration: BoxDecoration(
                                              color: selected == index 
                                                ? const Color(0xFF3B82F6).withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              selected == index
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                              size: 24,
                                              color: selected == index 
                                                ? const Color(0xFF3B82F6)
                                                : Colors.grey.shade600,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadiusDirectional
                                                    .circular(16),
                                            side: const BorderSide(
                                                color: Colors.white),
                                          ),
                                          title: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                                                  child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                                    children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 5.0,
                                                    ),
                                                                        child: Text(
                                                      '${index + 1}. ${HtmlUnescape().convert(section.title.toString())}',
                                                                        style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                          Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5.0),
                                                                            child: Row(
                                                                        children: [
                                                                                Expanded(
                                                                                  flex: 1,
                                                                                  child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: kTimeBackColor
                                                                .withOpacity(
                                                                    0.12),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                                      vertical: 5.0,
                                                                                    ),
                                                                                    child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                                            child: Text(
                                                              section
                                                                  .totalDuration
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                                          fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    kTimeColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                            ),
                                                                                ),
                                                      const SizedBox(
                                                        width: 10.0,
                                                      ),
                                                                                Expanded(
                                                                                  flex: 1,
                                                                                  child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                kLessonBackColor
                                                                    .withOpacity(
                                                                        0.12),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                                      vertical: 5.0,
                                                                                    ),
                                                                                    child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                                            child: Text(
                                                                              '${section.mLesson!.length} Lessons',
                                                              style:
                                                                  const TextStyle(
                                                                                          fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    kLessonColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                                  ),
                                                                                ),
                                                      const Expanded(
                                                          flex: 1,
                                                          child: Text("")),
                                                                        ],
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                      children: [
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  section.mLesson!.length,
                                              itemBuilder: (ctx, index) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 15.0),
                                                  child: Column(
                                                    children: [
                                                      LessonListItem(
                                                        lesson: section
                                                            .mLesson![index],
                                                        courseId:
                                                            loadedCourseDetails
                                                                .courseId!,
                                                      ),
                                                      if ((section.mLesson!
                                                                  .length -
                                                              1) !=
                                                          index)
                                                        Divider(
                                                          color: kGreyLightColor
                                                              .withOpacity(0.3),
                                                        ),
                                                      if ((section.mLesson!
                                                                  .length -
                                                              1) ==
                                                          index)
                                                        const SizedBox(
                                                            height: 10),
                                                    ],
                                                  ),
                                                );
                                              },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              // Certificate Section
                                                                                Container(
                                margin: const EdgeInsets.only(top: 20, bottom: 20),
                                padding: const EdgeInsets.all(15),
                                                                                  decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                                                        child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                                                                            children: [
                                                                                              Icon(
                                                Icons.verified,
                                                color: Color(0xFF6366F1),
                                                size: 16,
                                              ),
                                              SizedBox(width: 6),
                                                                                              Text(
                                                'Certificate Included',
                                                                                                style: TextStyle(
                                                  color: Color(0xFF6366F1),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                    ],
                                                                                  ),
                                    const SizedBox(height: 15),
                                    const Text(
                                      'Certificate You Will Get',
                                                                                      style: TextStyle(
                                        fontSize: 18,
                                                                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Upon successful completion of this course, you will receive a certificate of completion that you can share with your professional network.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF6366F1).withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          'assets/images/certificate.png',
                                          fit: BoxFit.cover,
                                        ),
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
                );
              }),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100), // Add margin to avoid overlap with bottom nav
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: Color(0xFF6366F1),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Assistant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // AI Assistant Content
                    Expanded(
                      child: AIAssistantScreen(
                        currentScreen: 'Course Details',
                        screenDetails: 'This is the Course Details screen.',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          backgroundColor: const Color(0xFF6366F1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<Courses>(builder: (context, courses, child) {
        final loadedCourseDetails = courses.getCourseDetail;
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Price display
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      loadedCourseDetails.price.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Buy Now or Enroll button
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final authToken = (prefs.getString('access_token') ?? '');
                    if (authToken.isNotEmpty) {
                      if (loadedCourseDetails.isPurchased!) {
                        // Already purchased, go to my courses
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MyCoursesScreen()
                          ),
                        );
                      } else if (loadedCourseDetails.isPaid == 1) {
                        // Paid course, go to payment
                        final emailPre = prefs.getString('email');
                        final passwordPre = prefs.getString('password');
                        var email = emailPre;
                        var password = passwordPre;
                        DateTime currentDateTime = DateTime.now();
                        int currentTimestamp = (currentDateTime.millisecondsSinceEpoch / 1000).floor();
                        
                        String authToken = 'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
                        final url = '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem';
                        
            Navigator.push(
                context,
                MaterialPageRoute(
                            builder: (context) => PaymentWebView(url: url),
                          ),
                        );
                        
                        CommonFunctions.showSuccessToast('Processing payment...');
                        if (!loadedCourseDetails.is_cart!) {
                          Provider.of<Courses>(context, listen: false)
                              .toggleCart(loadedCourseDetails.courseId!, false);
                        }
                      } else {
                        // Free course, enroll
                        await getEnroll(loadedCourseDetails.courseId.toString());
                        CommonFunctions.showSuccessToast('Course Successfully Enrolled');
                      }
                    } else {
                      CommonFunctions.showWarningToast('Please login first');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF2563EB),
                        ],
                      ),
                      color: null,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        loadedCourseDetails.isPurchased!
                            ? 'Go to Course'
                            : loadedCourseDetails.isPaid == 1
                                ? 'Buy Now'
                                : 'Enroll Now',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
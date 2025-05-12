// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:academy_lms_app/models/course_detail.dart';
import 'package:academy_lms_app/screens/payment_webview.dart';
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

                                          if (await canLaunchUrl(
                                              Uri.parse(url))) {
                                            await launchUrl(
                                              Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } else {
                                            throw 'Could not launch $url';
                                          }
                                          // } else if (msg1 == 'Added to cart') {
                                          //   setState(() {
                                          //     msg1 =
                                          //         'please tap again to Buy Now';
                                          //   });
                                          // }
                                          CommonFunctions.showSuccessToast(
                                              msg1);
                                              if (!loadedCourseDetails.is_cart!) {
                                                Provider.of<Courses>(context,
                                                listen: false)
                                            .toggleCart(
                                                loadedCourseDetails.courseId!,
                                                false);
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
                                          builder: (context) => TabsScreen(
                                                pageIndex: 1,
                                              )),
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
      appBar: const AppBarOne(logo: 'light_logo.png'),
      body: Container(
        height: MediaQuery.of(context).size.height * 1,
        color: kBackGroundColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kDefaultColor),
              )
            : Consumer<Courses>(builder: (context, courses, child) {
                final loadedCourseDetails = courses.getCourseDetail;
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full width thumbnail without radius
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Full width image with no radius or opacity overlay
                                Container(
                                  width: double.infinity,
                                  height: MediaQuery.of(context).size.height * .35,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        loadedCourseDetails.thumbnail.toString(),
                                      ),
                                    ),
                                  ),
                                ),
                                // Play button overlay
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
                                              videoUrl: url
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
                                              vimeoVideoId: vimeoVideoId
                                            ),
                                          )
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
                                    }
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Image.asset(
                                        'assets/images/play.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                // Wishlist button
                                Positioned(
                                  top: 15,
                                  right: 15,
                                  child: SizedBox(
                                    height: 45,
                                    width: 45,
                                    child: FittedBox(
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          if (_isAuth) {
                                            var msg = loadedCourseDetails.isWishlisted;
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) => buildPopupDialogWishList(
                                                context,
                                                loadedCourseDetails.isWishlisted,
                                                loadedCourseDetails.courseId,
                                                msg
                                              ),
                                            );
                                          } else {
                                            CommonFunctions.showSuccessToast('Please login first');
                                          }
                                        },
                                        tooltip: 'Wishlist',
                                        backgroundColor: loadedCourseDetails.isWishlisted!
                                            ? Colors.white
                                            : kGreyLightColor.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(57)
                                        ),
                                        child: Icon(
                                          loadedCourseDetails.isWishlisted! ? Icons.favorite : Icons.favorite,
                                          size: 30,
                                          color: loadedCourseDetails.isWishlisted! ? kDefaultColor : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Share button
                                Positioned(
                                  top: 15,
                                  left: 15,
                                  child: SizedBox(
                                    height: 45,
                                    width: 45,
                                    child: FittedBox(
                                      child: FloatingActionButton(
                                        onPressed: () async {
                                          await Share.share(loadedCourseDetails.shareableLink.toString());
                                        },
                                        tooltip: 'Share',
                                        backgroundColor: kGreyLightColor.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(57)
                                        ),
                                        child: const Icon(
                                          Icons.share,
                                          size: 25,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Course tabs
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  DefaultTabController(
                                    length: 2,
                                    child: Column(
                                      children: [
                                        TabBar(
                                          controller: _tabController,
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          indicator: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: kDefaultColor,
                                          ),
                                          unselectedLabelStyle: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                          labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: kWhiteColor,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          dividerHeight: 0,
                                          tabs: const <Widget>[
                                            Tab(
                                              child: Text(
                                                "About",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Text(
                                                "Lessons",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          constraints: BoxConstraints(
                                            minHeight: 500,
                                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                                          ),
                                          padding: const EdgeInsets.only(top: 20),
                                          child: TabBarView(
                                            controller: _tabController,
                                            children: [
                                              // About Tab
                                              SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Course Title
                                                    Text(
                                                      loadedCourseDetails.title.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 15),
                                                    
                                                    // Rating and Reviews
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          color: kStarColor,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          loadedCourseDetails.average_rating,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w400,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          '(${loadedCourseDetails.total_reviews.toString()} Reviews)',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w400,
                                                            color: kGreyLightColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 25),
                                                    
                                                    // What You Will Learn
                                                    const Text(
                                                      'What You Will Learn',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ...loadedCourseDetails.courseOutcomes.map((item) => 
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Icon(Icons.check_circle, color: kDefaultColor, size: 18),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                item,
                                                                style: const TextStyle(fontSize: 15),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ).toList(),
                                                    const SizedBox(height: 25),
                                                    
                                                    // What is Included
                                                    const Text(
                                                      'What is Included',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ...loadedCourseDetails.courseIncludes.map((item) => 
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Icon(Icons.check_circle, color: kDefaultColor, size: 18),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                item,
                                                                style: const TextStyle(fontSize: 15),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ).toList(),
                                                    const SizedBox(height: 25),
                                                    
                                                    // Course Requirements
                                                    const Text(
                                                      'Course Requirements',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ...loadedCourseDetails.courseRequirements.map((item) => 
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Icon(Icons.arrow_right, color: kDefaultColor, size: 22),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                item,
                                                                style: const TextStyle(fontSize: 15),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ).toList(),
                                                    const SizedBox(height: 50),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Lessons Tab
                                              SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Course Curriculum',
                                                      style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 15),
                                                    
                                                    // Course sections and lessons
                                                    ListView.builder(
                                                      key: Key('builder ${selected.toString()}'),
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: loadedCourseDetails.mSection!.length,
                                                      itemBuilder: (ctx, index) {
                                                        final section = loadedCourseDetails.mSection![index];
                                                        return Padding(
                                                          padding: const EdgeInsets.only(bottom: 10.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: kBackButtonBorderColor.withOpacity(0.05),
                                                                  blurRadius: 10,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Card(
                                                              elevation: 0.5,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
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
                                                                trailing: Icon(
                                                                  selected == index
                                                                      ? Icons.keyboard_arrow_up_rounded
                                                                      : Icons.keyboard_arrow_down_rounded,
                                                                  size: 30,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(10),
                                                                ),
                                                                title: Padding(
                                                                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        '${index + 1}. ${HtmlUnescape().convert(section.title.toString())}',
                                                                        style: const TextStyle(
                                                                          fontSize: 16,
                                                                          fontWeight: FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 8),
                                                                      Row(
                                                                        children: [
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 5,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: kTimeBackColor.withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(5),
                                                                            ),
                                                                            child: Text(
                                                                              section.totalDuration.toString(),
                                                                              style: const TextStyle(
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: kTimeColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(width: 10),
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 5,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: kLessonBackColor.withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(5),
                                                                            ),
                                                                            child: Text(
                                                                              '${section.mLesson!.length} Lessons',
                                                                              style: const TextStyle(
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: kLessonColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                children: [
                                                                  ListView.builder(
                                                                    shrinkWrap: true,
                                                                    physics: const NeverScrollableScrollPhysics(),
                                                                    itemCount: section.mLesson!.length,
                                                                    itemBuilder: (ctx, index) {
                                                                      return Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                                                        child: Column(
                                                                          children: [
                                                                            LessonListItem(
                                                                              lesson: section.mLesson![index],
                                                                              courseId: loadedCourseDetails.courseId!,
                                                                            ),
                                                                            if ((section.mLesson!.length - 1) != index)
                                                                              Divider(
                                                                                color: kGreyLightColor.withOpacity(0.3),
                                                                              ),
                                                                            if ((section.mLesson!.length - 1) == index)
                                                                              const SizedBox(height: 10),
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
                                                  ],
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
                          ],
                        ),
                      ),
                    ),
                    // Bottom price bar with action buttons
                    bottomPriceBar(),
                  ],
                );
              }),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
        padding: const EdgeInsets.only(right: 10.0, bottom: 18),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilterScreen(),
                ));
          },
          backgroundColor: kWhiteColor,
          shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: kDefaultColor),
              borderRadius: BorderRadius.circular(100)),
          child: SvgPicture.asset(
            'assets/icons/filter.svg',
            colorFilter: const ColorFilter.mode(
              kBlackColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

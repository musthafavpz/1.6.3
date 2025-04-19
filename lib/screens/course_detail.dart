// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:academy_lms_app/models/course_detail.dart';
import 'package:academy_lms_app/screens/cart.dart'; // Import the cart screen
import 'package:academy_lms_app/screens/payment_webview.dart'; // Import the payment webview screen
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

  // Colors
  final Color buyNowColor = const Color(0xFF5B72EE); // Premium blue
  final Color addToCartColor = const Color(0xFFEFEFF4); // Light gray
  final Color purchasedColor = const Color(0xFF4CAF50); // Success green
  final Color textDarkColor = const Color(0xFF333333); // Dark text
  final Color textLightColor = const Color(0xFF858585); // Light text
  final Color dividerColor = const Color(0xFFE0E0E0); // Divider color

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

    final data = jsonDecode(response.body);
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
    _tabController = TabController(length: 2, vsync: this); // Changed to 2 tabs
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
        setState(() {
          _isLoading = false;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _openPaymentWebView(String authToken, CourseDetail courseDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final emailPre = prefs.getString('email');
    final passwordPre = prefs.getString('password');
    var email = emailPre;
    var password = passwordPre;
    
    DateTime currentDateTime = DateTime.now();
    int currentTimestamp = (currentDateTime.millisecondsSinceEpoch / 1000).floor();

    String authEncoded = 'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
    final url = '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authEncoded&unique_id=academylaravelbycreativeitem';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebView(url: url),
      ),
    );
    
    if (!courseDetail.is_cart!) {
      Provider.of<Courses>(context, listen: false)
          .toggleCart(courseDetail.courseId!, false);
    }
    
    CommonFunctions.showSuccessToast(msg1);
  }

  @override
  Widget build(BuildContext context) {
    // Bottom navigation bar with improved styling
    Widget customNavBar() {
      return Consumer<Courses>(builder: (context, courses, child) {
        final loadedCourseDetails = courses.getCourseDetail;
        
        return Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Account button
              _isLoading
                ? const SizedBox(width: 40)
                : IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/account.svg',
                      colorFilter: const ColorFilter.mode(
                          kGreyLightColor, BlendMode.srcIn),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TabsScreen(pageIndex: 3),
                        ),
                      );
                    },
                  ),
              
              const Spacer(),
              
              // Action buttons based on course status
              if (loadedCourseDetails.isPurchased!)
                // Purchased button
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final authToken = (prefs.getString('access_token') ?? '');
                    if (authToken.isNotEmpty) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => TabsScreen(pageIndex: 1),
                        ),
                      );
                    } else {
                      CommonFunctions.showWarningToast('Please login first');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purchasedColor,
                    minimumSize: const Size(180, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Purchased',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                )
              else if (loadedCourseDetails.isPaid == 1)
                // Paid course - show add to cart and buy buttons
                Row(
                  children: [
                    // Add to cart button
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final authToken = (prefs.getString('access_token') ?? '');

                        if (authToken.isNotEmpty) {
                          Provider.of<Courses>(context, listen: false)
                              .toggleCart(loadedCourseDetails.courseId!, false);

                          if (loadedCourseDetails.is_cart!) {
                            CommonFunctions.showSuccessToast("Removed from cart");
                          } else {
                            CommonFunctions.showSuccessToast("Added to cart");
                            
                            // Navigate to cart screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CartScreen()),
                            );
                          }
                        } else {
                          CommonFunctions.showSuccessToast('Please login first');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: loadedCourseDetails.is_cart! ? buyNowColor : addToCartColor,
                        minimumSize: const Size(85, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13.0),
                          side: BorderSide(color: buyNowColor),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        loadedCourseDetails.is_cart! ? "In Cart" : 'Add to Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: loadedCourseDetails.is_cart! ? Colors.white : buyNowColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // Buy now button
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final authToken = (prefs.getString('access_token') ?? '');
                        if (authToken.isNotEmpty) {
                          _openPaymentWebView(authToken, loadedCourseDetails);
                        } else {
                          CommonFunctions.showWarningToast('Please login first');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buyNowColor,
                        minimumSize: const Size(85, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Free course - show enroll button
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final authToken = (prefs.getString('access_token') ?? '');
                    if (authToken.isNotEmpty) {
                      await getEnroll(loadedCourseDetails.courseId.toString());
                      CommonFunctions.showSuccessToast('Course Successfully Enrolled');
                    } else {
                      CommonFunctions.showWarningToast('Please login first');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buyNowColor,
                    minimumSize: const Size(180, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enroll Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      appBar: const AppBarOne(logo: 'light_logo.png'),
      body: Container(
        color: kBackGroundColor,
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            )
          : Consumer<Courses>(builder: (context, courses, child) {
              final loadedCourseDetails = courses.getCourseDetail;
              return Column(
                children: [
                  // Full width thumbnail with play button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Full width thumbnail without rounded corners
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.6),
                              BlendMode.dstATop,
                            ),
                            image: NetworkImage(
                              loadedCourseDetails.thumbnail.toString(),
                            ),
                          ),
                        ),
                      ),
                      
                      // Play button with improved styling
                      Material(
                        elevation: 8,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            if (loadedCourseDetails.preview != null) {
                              final previewUrl = loadedCourseDetails.preview!;
                              
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
                                final Match? match = regExp.firstMatch(
                                    loadedCourseDetails.preview.toString());
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
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.play_arrow_rounded, 
                              size: 40, 
                              color: buyNowColor,
                            ),
                          ),
                        ),
                      ),
                      
                      // Wishlist button
                      Positioned(
                        top: 15,
                        right: 15,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              loadedCourseDetails.isWishlisted!
                                ? Icons.favorite
                                : Icons.favorite_border,
                              size: 22,
                              color: loadedCourseDetails.isWishlisted!
                                ? Colors.red
                                : Colors.grey,
                            ),
                            onPressed: () {
                              if (_isAuth) {
                                var msg = loadedCourseDetails.isWishlisted;
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => buildPopupDialogWishList(
                                    context,
                                    loadedCourseDetails.isWishlisted,
                                    loadedCourseDetails.courseId,
                                    msg,
                                  ),
                                );
                              } else {
                                CommonFunctions.showSuccessToast('Please login first');
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Tab bar with Overview and Lessons tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: buyNowColor,
                      unselectedLabelColor: textLightColor,
                      indicatorColor: buyNowColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: "Overview"),
                        Tab(text: "Lessons"),
                      ],
                    ),
                  ),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // OVERVIEW TAB
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Course title and price
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      loadedCourseDetails.title.toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    loadedCourseDetails.price.toString(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: buyNowColor,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 15),
                              
                              // Ratings and reviews
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: kStarColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    loadedCourseDetails.average_rating,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '(${loadedCourseDetails.total_reviews.toString()} Reviews)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 25),
                              
                              // Course details in cards
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // What is Included section
                                    ExpansionTile(
                                      initiallyExpanded: true,
                                      iconColor: buyNowColor,
                                      childrenPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      title: Text(
                                        "What is Included",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textDarkColor,
                                        ),
                                      ),
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: loadedCourseDetails.courseIncludes.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 18,
                                                    color: buyNowColor,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      loadedCourseDetails.courseIncludes[index],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    
                                    // What you will learn section
                                    ExpansionTile(
                                      initiallyExpanded: false,
                                      iconColor: buyNowColor,
                                      childrenPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      title: Text(
                                        "What you will learn",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textDarkColor,
                                        ),
                                      ),
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: loadedCourseDetails.courseOutcomes.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 18,
                                                    color: buyNowColor,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      loadedCourseDetails.courseOutcomes[index],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    
                                    // Course requirements section
                                    ExpansionTile(
                                      initiallyExpanded: false,
                                      iconColor: buyNowColor,
                                      childrenPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      title: Text(
                                        "Course Requirements",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textDarkColor,
                                        ),
                                      ),
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: loadedCourseDetails.courseRequirements.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_right,
                                                    size: 20,
                                                    color: buyNowColor,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      loadedCourseDetails.courseRequirements[index],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // LESSONS TAB
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course Curriculum',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textDarkColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Lesson sections
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
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                          ),
                                        ],
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
                                        iconColor: buyNowColor,
                                        collapsedIconColor: textLightColor,
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        childrenPadding: const

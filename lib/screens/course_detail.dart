// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:academy_lms_app/models/course_detail.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/screens/payment_webview.dart';
import 'package:academy_lms_app/screens/cart.dart';
import 'package:academy_lms_app/widgets/from_vimeo_player.dart';
import 'package:academy_lms_app/widgets/new_youtube_player.dart';
import 'package:academy_lms_app/widgets/no_preview_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/common_functions.dart';
import '../widgets/from_network.dart';
import '../widgets/lesson_list_item.dart';
import '../widgets/util.dart';
import 'filter_screen.dart';
import 'cart.dart';

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

  Widget _buildAboutSection(String title, List<String> items, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                IconButton(
                                    icon: SvgPicture.asset(
                                      'assets/icons/account.svg',
                                      colorFilter: const ColorFilter.mode(
                                          kGreyLightColor, BlendMode.srcIn),
                                    ),
                                    onPressed: () {
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
                          thickness: 1.0,
                          color: kGreyLightColor,
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
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          final emailPre =
                                              prefs.getString('email');
                                          final passwordPre =
                                              prefs.getString('password');
                                          var email = emailPre;
                                          var password = passwordPre;
                                          
                                          DateTime currentDateTime =
                                              DateTime.now();
                                          int currentTimestamp = (currentDateTime
                                                      .millisecondsSinceEpoch /
                                                  1000)
                                              .floor();

                                          String authToken =
                                              'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
                                          
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => PaymentWebView(
                                                url: '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem',
                                              ),
                                            ),
                                          );
                                          
                                          CommonFunctions.showSuccessToast('Processing payment...');
                                          if (!loadedCourseDetails.is_cart!) {
                                            Provider.of<Courses>(context,
                                            listen: false)
                                        .toggleCart(
                                            loadedCourseDetails.courseId!,
                                            false);
                                          }
                                        }
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
                                        Provider.of<Courses>(context,
                                                listen: false)
                                            .toggleCart(
                                                loadedCourseDetails.courseId!,
                                                false);

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const CartScreen(),
                                          ),
                                        );
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
                                          CommonFunctions.showSuccessToast(
                                              'Course Succesfully Enrolled');
                                        }
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
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          fit: StackFit.loose,
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              height: MediaQuery.of(context).size.height * .31,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    loadedCourseDetails.thumbnail.toString(),
                                  ),
                                )
                              ),
                            ),
                            ClipOval(
                              child: InkWell(
                                onTap: () {
                                  if (loadedCourseDetails.preview != null) {
                                    final previewUrl =
                                        loadedCourseDetails.preview!;
                                    print(previewUrl);

                                    final isYouTube =
                                        previewUrl.contains("youtube.com") ||
                                            previewUrl.contains("youtu.be");
                                    final isVimeo =
                                        previewUrl.contains("vimeo.com");
                                    final isDrive =
                                        previewUrl.contains("drive.google.com");
                                    final isMp4 = RegExp(r"\.mp4(\?|$)")
                                        .hasMatch(previewUrl);
                                    final isWebm = RegExp(r"\.webm(\?|$)")
                                        .hasMatch(previewUrl);
                                    final isOgg = RegExp(r"\.ogg(\?|$)")
                                        .hasMatch(previewUrl);

                                    if (isYouTube) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              YoutubeVideoPlayerFlutter(
                                            courseId:
                                                loadedCourseDetails.courseId!,
                                            videoUrl: previewUrl,
                                          ),
                                        ),
                                      );
                                    } else if (isDrive) {
                                      final RegExp regExp =
                                          RegExp(r'[-\w]{25,}');
                                      final Match? match = regExp.firstMatch(
                                          loadedCourseDetails.preview
                                              .toString());
                                      String url =
                                          'https://drive.google.com/uc?export=download&id=${match!.group(0)}';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PlayVideoFromNetwork(
                                                    courseId:
                                                        loadedCourseDetails
                                                            .courseId!,
                                                    videoUrl: url)),
                                      );
                                    } else if (isVimeo) {
                                      String vimeoVideoId = loadedCourseDetails
                                          .preview!
                                          .split('/')
                                          .last;
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FromVimeoPlayer(
                                                    courseId:
                                                        loadedCourseDetails
                                                            .courseId!,
                                                    vimeoVideoId: vimeoVideoId),
                                          ));
                                    } else if (isMp4 || isOgg || isWebm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PlayVideoFromNetwork(
                                            courseId:
                                                loadedCourseDetails.courseId!,
                                            videoUrl: previewUrl,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NoPreviewVideo(),
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
                                        var msg =
                                            loadedCourseDetails.isWishlisted;
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              buildPopupDialogWishList(
                                                  context,
                                                  loadedCourseDetails
                                                      .isWishlisted,
                                                  loadedCourseDetails.courseId,
                                                  msg),
                                        );
                                      } else {
                                        CommonFunctions.showSuccessToast(
                                            'Please login first');
                                      }
                                    },
                                    tooltip: 'Wishlist',
                                    backgroundColor:
                                        loadedCourseDetails.isWishlisted!
                                            ? Colors.white
                                            : kGreyLightColor.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(57)),
                                    child: Icon(
                                      loadedCourseDetails.isWishlisted!
                                          ? Icons.favorite
                                          : Icons.favorite,
                                      size: 30,
                                      color: loadedCourseDetails.isWishlisted!
                                          ? kDefaultColor
                                          : Colors.white,
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                loadedCourseDetails.price.toString(),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w500),
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
                                          indicatorSize:
                                              TabBarIndicatorSize.tab,
                                          indicator: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              color: kDefaultColor),
                                          unselectedLabelStyle: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: kWhiteColor,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          dividerHeight: 0,
                                          tabs: const <Widget>[
                                            Tab(
                                              child: Text(
                                                "About Course",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "Lessons",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        height: 300,
                                        padding: const EdgeInsets.only(
                                            right: 10,
                                            left: 10,
                                            top: 0,
                                            bottom: 10),
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                            SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildAboutSection(
                                                    "What is Included",
                                                    loadedCourseDetails.courseIncludes,
                                                    Colors.blue.shade50,
                                                    Colors.blue,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  _buildAboutSection(
                                                    "What You Will Learn",
                                                    loadedCourseDetails.courseOutcomes, 
                                                    Colors.green.shade50,
                                                    Colors.green,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  _buildAboutSection(
                                                    "Course Requirements",
                                                    loadedCourseDetails.courseRequirements,
                                                    Colors.amber.shade50,
                                                    Colors.amber.shade800,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ListView.builder(
                                                    key: Key('builder ${selected.toString()}'),
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemCount: loadedCourseDetails.mSection!.length,
                                                    itemBuilder: (ctx, index) {
                                                      final section = loadedCourseDetails.mSection![index];
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 5.0),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: kBackButtonBorderColor.withOpacity(0.05),
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
                                                              trailing: Icon(
                                                                selected == index
                                                                    ? Icons.keyboard_arrow_up_rounded
                                                                    : Icons.keyboard_arrow_down_rounded,
                                                                size: 35,
                                                              ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadiusDirectional.circular(16),
                                                                side: const BorderSide(color: Colors.white),
                                                              ),
                                                              title: Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Align(
                                                                      alignment: Alignment.centerLeft,
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          vertical: 5.0,
                                                                        ),
                                                                        child: Text(
                                                                          '${index + 1}. ${HtmlUnescape().convert(section.title.toString())}',
                                                                          style: const TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                                                                      child: Row(
                                                                        children: [
                                                                          Expanded(
                                                                            flex: 1,
                                                                            child: Container(
                                                                              decoration: BoxDecoration(
                                                                                color: kTimeBackColor.withOpacity(0.12),
                                                                                borderRadius: BorderRadius.circular(5),
                                                                              ),
                                                                              padding: const EdgeInsets.symmetric(
                                                                                vertical: 5.0,
                                                                              ),
                                                                              child: Align(
                                                                                alignment: Alignment.center,
                                                                                child: Text(
                                                                                  section.totalDuration.toString(),
                                                                                  style: const TextStyle(
                                                                                    fontSize: 10,
                                                                                    fontWeight: FontWeight.w400,
                                                                                    color: kTimeColor,
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
                                                                              decoration: BoxDecoration(
                                                                                color: kLessonBackColor.withOpacity(0.12),
                                                                                borderRadius: BorderRadius.circular(5),
                                                                              ),
                                                                              padding: const EdgeInsets.symmetric(
                                                                                vertical: 5.0,
                                                                              ),
                                                                              child: Align(
                                                                                alignment: Alignment.center,
                                                                                child: Text(
                                                                                  '${section.mLesson!.length} Lessons',
                                                                                  style: const TextStyle(
                                                                                    fontSize: 10,
                                                                                    fontWeight: FontWeight.w400,
                                                                                    color: kLessonColor,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const Expanded(flex: 1, child: Text("")),
                                                                        ],
                                                                      ),
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
                              ),
                              const SizedBox(
                                height: 10,
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
      bottomNavigationBar: customNavBar(),
    );
  }
}

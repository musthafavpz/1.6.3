import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/screens/login.dart';
import 'package:academy_lms_app/screens/onboarding_screen.dart';
import 'package:academy_lms_app/screens/splash.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/screens/welcome_screen.dart';
import 'package:academy_lms_app/screens/instructor_screen.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth.dart';
import 'providers/categories.dart';
import 'providers/courses.dart';
import 'providers/misc_provider.dart';
import 'providers/my_courses.dart';
import 'providers/ai_assistant_provider.dart';
import 'screens/account_remove_screen.dart';
import 'screens/ai_assistant.dart';
import 'screens/category_details.dart';
import 'screens/certificates_screen.dart';
import 'screens/course_detail.dart';
import 'screens/courses_screen.dart';
import 'screens/sub_category.dart';
import 'package:flutter/services.dart';
import 'utils/api_utils.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? detachedCallBack;

  LifecycleEventHandler({
    this.detachedCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.detached:
        if (detachedCallBack != null) {
          await detachedCallBack!();
        }
        break;
      default:
        break;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.root.onRecord.listen((LogRecord rec) {
    debugPrint(
        '${rec.loggerName}>${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  
  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_completed') != true;
  
  // Check if user is already logged in
  final token = prefs.getString('access_token');
  final isLoggedIn = token != null && token.isNotEmpty;
  
  runApp(MyApp(showOnboarding: showOnboarding, isLoggedIn: isLoggedIn));
  
  // Dispose API utils when app is closed
  WidgetsBinding.instance.addObserver(
    LifecycleEventHandler(
      detachedCallBack: () async {
        ApiUtils.dispose();
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final bool isLoggedIn;
  
  const MyApp({super.key, this.showOnboarding = true, this.isLoggedIn = false});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => Auth(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Categories(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Languages(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AIAssistantProvider(),
        ),
        ChangeNotifierProxyProvider<Auth, Courses>(
          create: (ctx) => Courses([], [],),
          update: (ctx, auth, prevoiusCourses) => Courses(
            prevoiusCourses == null ? [] : prevoiusCourses.items,
            prevoiusCourses == null ? [] : prevoiusCourses.topItems,
          ),
        ),
        ChangeNotifierProxyProvider<Auth, MyCourses>(
          create: (ctx) => MyCourses([], []),
          update: (ctx, auth, previousMyCourses) => MyCourses(
            previousMyCourses == null ? [] : previousMyCourses.items,
            previousMyCourses == null ? [] : previousMyCourses.sectionItems,
          ),
        ),
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Academy LMS App',
          theme: ThemeData(
            fontFamily: 'Poppins',
            colorScheme: const ColorScheme.light(primary: kWhiteColor),
            useMaterial3: true,
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.black,
              selectionColor: Colors.black12,
              selectionHandleColor: Colors.black54,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              hintStyle: TextStyle(color: Colors.grey),
              labelStyle: TextStyle(color: Colors.black87),
              floatingLabelStyle: TextStyle(color: Color(0xFF6366F1)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6366F1)),
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: isLoggedIn 
                ? const TabsScreen(pageIndex: 0) 
                : (showOnboarding ? const OnboardingScreen() : const WelcomeScreen()),
          routes: {
            '/home': (ctx) => const TabsScreen(
                  pageIndex: 0,
                ),
            '/login': (ctx) => const LoginScreen(),
            '/welcome': (ctx) => const WelcomeScreen(),
            OnboardingScreen.routeName: (ctx) => const OnboardingScreen(),
            WelcomeScreen.routeName: (ctx) => const WelcomeScreen(),
            CoursesScreen.routeName: (ctx) => const CoursesScreen(),
            CategoryDetailsScreen.routeName: (ctx) =>
                const CategoryDetailsScreen(),
            CourseDetailScreen.routeName: (ctx) => const CourseDetailScreen(),
            SubCategoryScreen.routeName: (ctx) => const SubCategoryScreen(),
            AccountRemoveScreen.routeName: (ctx) => const AccountRemoveScreen(),
            CertificatesScreen.routeName: (ctx) => const CertificatesScreen(),
            AIAssistantScreen.routeName: (ctx) => const AIAssistantScreen(),
            InstructorScreen.routeName: (ctx) => const InstructorScreen(),
          },
        ),
      ),
    );
  }
}

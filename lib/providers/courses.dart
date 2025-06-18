// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:async';

import 'package:academy_lms_app/models/cart_tools_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/course.dart';
import '../models/course_detail.dart';
import '../models/lesson.dart';
import '../models/section.dart';

class Courses with ChangeNotifier {
  List<Course> _items = [];
  List<Course> _topItems = [];
  List<CourseDetail> _courseDetailsitems = [];
  List<CourseDetails> _courseDetails = [];
  List<Map<String, dynamic>> _topInstructors = [];
  CartTools? _cartTools;
  
  // API call management
  Timer? _debounceTimer;
  http.Client? _httpClient;
  bool _isLoadingTopCourses = false;
  bool _isLoadingInstructors = false;

  Courses(
    this._items,
    this._topItems,
  ) {
    _httpClient = http.Client();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  List<Course> get items {
    return [..._items];
  }

  List<Course> get cartItems {
    return [..._items];
  }

  List<Course> get topItems {
    return [..._topItems];
  }

  CourseDetail get getCourseDetail {
    if (_courseDetailsitems.isEmpty) {
      throw Exception('Course details not loaded yet');
    }
    return _courseDetailsitems.first;
  }

  CourseDetails get courseDetails {
    if (_courseDetails.isEmpty) {
      throw Exception('Course details not loaded yet');
    }
    return _courseDetails.first;
  }

  CartTools? get cartTools => _cartTools;

  int get itemCount {
    return _items.length;
  }

  Course findById(id) {
    // return _topItems.firstWhere((course) => course.id == id);
    return _items.firstWhere((course) => course.id == id,
        orElse: () => _topItems.firstWhere((course) => course.id == id));
  }

  Future<void> fetchTopCourses() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingTopCourses) {
      return;
    }
    
    _isLoadingTopCourses = true;
    
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    // Add a small delay to debounce rapid calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      var url = '$baseUrl/api/top_courses';
      try {
        final response = await _httpClient!.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          // Check if response is HTML (error page) instead of JSON
          if (response.body.trim().startsWith('<!DOCTYPE html>') || 
              response.body.trim().startsWith('<html>')) {
            throw Exception('Server returned HTML instead of JSON. Please try again later.');
          }
          
          final extractedData = json.decode(response.body) as List;
          if (extractedData == null) {
            return;
          }
          
          _topItems = buildCourseList(extractedData);
          notifyListeners();
        } else {
          throw Exception('Failed to load courses: ${response.statusCode}');
        }
      } catch (error) {
        print('Error fetching top courses: $error');
        rethrow;
      } finally {
        _isLoadingTopCourses = false;
      }
    });
  }

  Future<void> fetchCoursesByCategory(int categoryId) async {
    var url = '$baseUrl/api/category_wise_course?category_id=$categoryId';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body) as List;
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      // print(extractedData);

      _items = buildCourseList(extractedData);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // Future<void> fetchCoursesBySearchQuery(String searchQuery) async {
  //   var url =
  //       '$baseUrl/api/courses_by_search_string?search_string=$searchQuery';
  //   // print(url);
  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     final extractedData = json.decode(response.body) as List;
  //     // ignore: unnecessary_null_comparison
  //     if (extractedData == null) {
  //       return;
  //     }
  //     // print(extractedData);

  //     _items = buildCourseList(extractedData);
  //     notifyListeners();
  //   } catch (error) {
  //     rethrow;
  //   }
  // }
  Future<void> fetchCoursesBySearchQuery(String searchQuery) async {
    if (searchQuery.isEmpty) {
      throw Exception('Search query cannot be empty');
    }

    var url =
        '$baseUrl/api/courses_by_search_string?search_string=$searchQuery';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }

      if (response.body.isEmpty) {
        throw Exception('Response body is empty');
      }

      final extractedData = json.decode(response.body);
      if (extractedData == null || extractedData is! List) {
        throw Exception('Invalid data format received from server');
      }

      _items = buildCourseList(extractedData);
      print(url);
      notifyListeners();
    } catch (error) {
      print('Error: $error');
      rethrow;
    }
  }

  Future<void> filterCourses(
      String selectedCategory,
      String selectedPrice,
      String selectedLevel,
      String selectedLanguage,
      String selectedRating) async {
    var url =
        '$baseUrl/api/filter_course?selected_category=$selectedCategory&selected_price=$selectedPrice&selected_level=$selectedLevel&selected_language=$selectedLanguage&selected_rating=$selectedRating&selected_search_string=';
    // print(url);
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body) as List;
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      // print(extractedData);

      _items = buildCourseList(extractedData);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchMyWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/my_wishlist';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });
      final extractedData = json.decode(response.body) as List;
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      _items = buildCourseList(extractedData);
      // print(_items);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchCartlist() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/cart_list';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });
      final extractedData = json.decode(response.body);
      print(extractedData);

      if (extractedData == null) {
        return;
      }

      if (extractedData is List) {
        _items = buildCourseList(extractedData);
      } else if (extractedData is Map<String, dynamic> &&
          extractedData.containsKey('courses')) {
        _items = buildCourseList(extractedData['courses']);
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  List<Course> buildCourseList(List extractedData) {
    final List<Course> loadedCourses = [];
    for (var courseData in extractedData) {
      loadedCourses.add(Course(
        id: courseData['id'],
        title: courseData['title'],
        thumbnail: courseData['thumbnail'],
        preview: courseData['preview'],
        price: courseData['price'],
        price_cart: courseData['price_cart'],
        isPaid: courseData['is_paid'],
        instructor: courseData['instructor_name'],
        instructorImage: courseData['instructor_image'],
        total_reviews: courseData['total_reviews'],
        average_rating: courseData['average_rating'],
        numberOfEnrollment: courseData['total_enrollment'],
        shareableLink: courseData['shareable_link'],
        // courseOverviewProvider: courseData['course_overview_provider'],
        // courseOverviewUrl: courseData['video_url'],
        // vimeoVideoId: courseData['vimeo_video_id'],
      ));
      // print(catData['name']);
    }
    return loadedCourses;
  }

  Future<void> toggleWishlist(int courseId, bool removeItem) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/toggle_wishlist_items?course_id=$courseId';
    if (!removeItem) {
      _courseDetailsitems.first.isWishlisted!
          ? _courseDetailsitems.first.isWishlisted = false
          : _courseDetailsitems.first.isWishlisted = true;
      notifyListeners();
    }
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'removed') {
        if (removeItem) {
          final existingMyCourseIndex =
              _items.indexWhere((mc) => mc.id == courseId);

          _items.removeAt(existingMyCourseIndex);
          notifyListeners();
        } else {
          _courseDetailsitems.first.isWishlisted = false;
        }
      } else if (responseData['status'] == 'added') {
        if (!removeItem) {
          _courseDetailsitems.first.isWishlisted = true;
        }
      }
      // notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // Future<void> toggleCart(int courseId, bool removeItem) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final authToken = (prefs.getString('access_token') ?? '');
  //   var url = '$baseUrl/api/toggle_cart_items?course_id=$courseId';
  //   try {
  //     final response = await http.get(Uri.parse(url), headers: {
  //       'Content-Type': 'application/json',
  //       'Accept': 'application/json',
  //       'Authorization': 'Bearer $authToken',
  //     });
  //     final responseData = json.decode(response.body);
  //     if (responseData['status'] == 'removed') {
  //       if (removeItem) {
  //         final existingMyCourseIndex =
  //             _items.indexWhere((mc) => mc.id == courseId);

  //         _items.removeAt(existingMyCourseIndex);
  //         notifyListeners();
  //       }
  //     }
  //     // notifyListeners();
  //   } catch (error) {
  //     rethrow;
  //   }
  // }

Future<void> toggleCart(int courseId, bool removeItem) async {
  final prefs = await SharedPreferences.getInstance();
  final authToken = (prefs.getString('access_token') ?? '');
  var url = '$baseUrl/api/toggle_cart_items?course_id=$courseId';

  // Optimistically update the local state for immediate UI feedback
  if (!removeItem) {
    _courseDetailsitems.first.is_cart!
        ? _courseDetailsitems.first.is_cart = false
        : _courseDetailsitems.first.is_cart = true;
    notifyListeners();
  }

  try {
    final response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $authToken',
    });

    final responseData = json.decode(response.body);

    if (responseData['status'] == 'removed') {
      if (removeItem) {
        // Remove the course from the `_items` list if needed
        final existingMyCourseIndex =
            _items.indexWhere((mc) => mc.id == courseId);

        if (existingMyCourseIndex != -1) {
          _items.removeAt(existingMyCourseIndex);
          notifyListeners();
        }
      } else {
        _courseDetailsitems.first.is_cart = false;
      }
    } else if (responseData['status'] == 'added') {
      if (!removeItem) {
        _courseDetailsitems.first.is_cart = true;
      }
    }

    // Notify listeners to ensure UI updates with the latest state
    notifyListeners();
  } catch (error) {
    rethrow;
  }
}

// Future<void> toggleCart(int courseId, bool removeItem) async {
//   final prefs = await SharedPreferences.getInstance();
//   final authToken = (prefs.getString('access_token') ?? '');
//   var url = '$baseUrl/api/toggle_cart_items?course_id=$courseId';

//   try {
//     final response = await http.get(Uri.parse(url), headers: {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       'Authorization': 'Bearer $authToken',
//     });
//     final responseData = json.decode(response.body);

//     if (responseData['status'] == 'removed') {
//       if (removeItem) {
//         // Find and remove the item locally
//         final existingMyCourseIndex =
//             _items.indexWhere((mc) => mc.id == courseId);
//         if (existingMyCourseIndex >= 0) {
//           _items.removeAt(existingMyCourseIndex);
//         }
//       }
//       // Update the is_cart property in the `_items` list
//       final index = _items.indexWhere((mc) => mc.id == courseId);
//       if (index != -1) {
//         _courseDetailsitems[index].is_cart = false;
//       }
//     } else if (responseData['status'] == 'added') {
//       // Update the is_cart property in the `_items` list
//       final index = _items.indexWhere((mc) => mc.id == courseId);
//       if (index != -1) {
//         _courseDetailsitems[index].is_cart = true;
//       }
//     }

//     // Notify listeners to rebuild the UI
//     notifyListeners();
//   } catch (error) {
//     rethrow;
//   }
// }


  Future<void> fetchCourseDetailById(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/course_details_by_id?course_id=$courseId';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final extractedData = json.decode(response.body) as List;
      if (extractedData.isEmpty) {
        return;
      }

      final List<CourseDetail> loadedCourseDetails = [];
      for (var courseData in extractedData) {
        if (courseData['requirements'] is List) {
          print('courseData["requirements"] is a List');
        } else {
          print('courseData["requirements"] is not a List');
        }
        loadedCourseDetails.add(CourseDetail(
          courseId: courseData['id'],
          title: courseData['title'],
          thumbnail: courseData['thumbnail'],
          price: courseData['price'],
          isPaid: courseData['is_paid'],
          instructor: courseData['instructor_name'],
          instructorImage: courseData['instructor_image'],
          total_reviews: courseData['total_reviews'],
          average_rating: courseData['average_rating'],
          price_cart: courseData['price_cart'],
          numberOfEnrollment: courseData['total_enrollment'],
          shareableLink: courseData['shareable_link'],
          courseIncludes:
              (courseData['includes'] as List<dynamic>).cast<String>(),
          courseRequirements: courseData['requirements'] is List
              ? (courseData['requirements'] as List<dynamic>).cast<String>()
              : courseData['requirements'] is Map
                  ? (courseData['requirements'] as Map<dynamic, dynamic>)
                      .values
                      .toList()
                      .cast<String>()
                  : <String>[], // Default to an empty list if neither List nor Map
          courseOutcomes: courseData['outcomes'] is List
              ? (courseData['outcomes'] as List<dynamic>).cast<String>()
              : courseData['outcomes'] is Map
                  ? (courseData['outcomes'] as Map<dynamic, dynamic>)
                      .values
                      .toList()
                      .cast<String>()
                  : <String>[], // Default to an empty list if neither List nor Map
          // courseIncludes:
          //     (courseData['includes'] as List<dynamic>).cast<String>(),
          // courseOutcomes:
          //     (courseData['outcomes'] as List<dynamic>).cast<String>(),
          isWishlisted: courseData['is_wishlisted'],
          is_cart: courseData['is_cart'],
          preview: courseData['preview'],
          isPurchased: (courseData['is_purchased'] is int)
              ? courseData['is_purchased'] == 1
                  ? true
                  : false
              : courseData['is_purchased'],
          mSection:
              buildCourseSections(courseData['sections'] as List<dynamic>),
        ));
      }
      // print(loadedCourseDetails.first.courseOutcomes.last);
      // _items = buildCourseList(extractedData);
      _courseDetailsitems = loadedCourseDetails;
      // _courseDetail = loadedCourseDetails.first;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

// course details
  Future<void> fetchCourseDetails(String? courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('access_token') ?? '');

    var url = "$baseUrl/api/course_details_by_id?course_id=$courseId";
    print(url);

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        // final jsonData = json.decode(response.body);
        // _courseDetails = CourseDetails.fromJson(jsonData);
        List<dynamic> courseJson = jsonDecode(response.body);
        _courseDetails =
            courseJson.map((data) => CourseDetails.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load course details');
      }
    } catch (error) {
      throw error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> getEnrolled(int courseId) async {
    const authToken = 'await SharedPreferenceHelper().getAuthToken()';
    var url =
        '$baseUrl/api/enroll_free_course?course_id=$courseId&auth_token=$authToken';
    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);
      if (responseData['message'] == 'success') {
        _courseDetailsitems.first.isPurchased = true;

        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  List<Section> buildCourseSections(List extractedSections) {
    final List<Section> loadedSections = [];

    for (var sectionData in extractedSections) {
      loadedSections.add(Section(
        id: sectionData['id'],
        numberOfCompletedLessons: sectionData['completed_lesson_number'],
        title: sectionData['title'],
        totalDuration: sectionData['total_duration'],
        lessonCounterEnds: sectionData['lesson_counter_ends'],
        lessonCounterStarts: sectionData['lesson_counter_starts'],
        mLesson: buildCourseLessons(sectionData['lessons'] as List<dynamic>),
      ));
    }
    // print(loadedSections.first.title);
    return loadedSections;
  }

  List<Lesson> buildCourseLessons(List extractedLessons) {
    final List<Lesson> loadedLessons = [];

    for (var lessonData in extractedLessons) {
      loadedLessons.add(Lesson(
        id: lessonData['id'],
        title: lessonData['title'],
        duration: lessonData['duration'],
        lessonType: lessonData['lesson_type'],
        isFree: lessonData['is_free'],
        videoUrl: lessonData['video_url'],
        summary: lessonData['summary'],
        attachmentType: lessonData['attachment_type'],
        attachment: lessonData['attachment'],
        attachmentUrl: lessonData['attachment_url'],
        isCompleted: lessonData['is_completed'].toString(),
        videoUrlWeb: lessonData['video_url_web'],
        videoTypeWeb: lessonData['video_type_web'],
        vimeoVideoId: lessonData['vimeo_video_id'],
      ));
    }
    // print(loadedLessons.first.title);
    return loadedLessons;
  }

  List<Map<String, dynamic>> get topInstructors {
    return [..._topInstructors];
  }

  Future<void> fetchTopInstructors() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingInstructors) {
      return;
    }
    
    _isLoadingInstructors = true;
    
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/top_courses';
    
    try {
      final response = await _httpClient!.get(
        Uri.parse(url), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Check if response is HTML (error page) instead of JSON
        if (response.body.trim().startsWith('<!DOCTYPE html>') || 
            response.body.trim().startsWith('<html>')) {
          throw Exception('Server returned HTML instead of JSON. Please try again later.');
        }
        
        final extractedData = json.decode(response.body) as List;
        
        // Create a map to accumulate instructor data
        final Map<String, Map<String, dynamic>> instructorsMap = {};
        
        // Process all courses to gather instructor data
        for (var courseData in extractedData) {
          final instructorName = courseData['instructor_name'];
          final instructorImage = courseData['instructor_image'];
          
          if (instructorName != null && instructorName.isNotEmpty) {
            // If instructor already exists in map, update counts
            if (instructorsMap.containsKey(instructorName)) {
              instructorsMap[instructorName]!['courseCount'] = instructorsMap[instructorName]!['courseCount'] + 1;
              instructorsMap[instructorName]!['totalEnrollment'] = (instructorsMap[instructorName]!['totalEnrollment'] ?? 0) + 
                                                                (courseData['total_enrollment'] ?? 0);
            } else {
              // Add new instructor
              instructorsMap[instructorName] = {
                'name': instructorName,
                'image': instructorImage,
                'courseCount': 1,
                'totalEnrollment': courseData['total_enrollment'] ?? 0,
                'rating': courseData['average_rating'] ?? 0.0
              };
            }
          }
        }
        
        // Convert map to list
        final instructorsList = instructorsMap.values.toList();
        
        // Sort by total enrollment (descending)
        instructorsList.sort((a, b) => (b['totalEnrollment'] ?? 0).compareTo(a['totalEnrollment'] ?? 0));
        
        _topInstructors = instructorsList;
        notifyListeners();
      } else {
        throw Exception('Failed to load instructors: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching top instructors: $error');
      rethrow;
    } finally {
      _isLoadingInstructors = false;
    }
  }
}

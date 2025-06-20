import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/lesson.dart';
import '../models/my_course.dart';
import '../models/section.dart';

class MyCourses with ChangeNotifier {
  List<MyCourse> _items = [];
  List<Section> _sectionItems = [];
  
  // API call management
  Timer? _debounceTimer;
  http.Client? _httpClient;
  bool _isLoadingMyCourses = false;

  MyCourses(this._items, this._sectionItems) {
    _httpClient = http.Client();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  List<MyCourse> get items {
    return [..._items];
  }

  List<Section> get sectionItems {
    return [..._sectionItems];
  }

  int get itemCount {
    return _items.length;
  }

  MyCourse findById(int id) {
    return _items.firstWhere((myCourse) => myCourse.id == id);
  }

  Future<void> fetchMyCourses() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingMyCourses) {
      return;
    }
    
    _isLoadingMyCourses = true;
    
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    // Add a small delay to debounce rapid calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      final authToken = (prefs.getString('access_token') ?? '');
      var url = '$baseUrl/api/my_courses';
      
      try {
        final response = await _httpClient!.get(
          Uri.parse(url), 
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          // Check if response is HTML (error page) instead of JSON
          if (response.body.trim().startsWith('<!DOCTYPE html>') || 
              response.body.trim().startsWith('<html>')) {
            throw Exception('Server returned HTML instead of JSON. Please try again later.');
          }
          
          final extractedData = json.decode(response.body) as List;
          
          if (extractedData.isEmpty || extractedData == null) {
            return;
          }
          
          _items = buildMyCourseList(extractedData);
          notifyListeners();
        } else {
          throw Exception('Failed to load my courses: ${response.statusCode}');
        }
      } catch (error) {
        print('Error fetching my courses: $error');
        rethrow;
      } finally {
        _isLoadingMyCourses = false;
      }
    });
  }

  List<MyCourse> buildMyCourseList(List extractedData) {
    final List<MyCourse> loadedCourses = [];
    for (var courseData in extractedData) {
      loadedCourses.add(MyCourse(
        id: courseData['id'],
        title: courseData['title'],
        thumbnail: courseData['thumbnail'],
        price: courseData['price'],
        instructor: courseData['instructor_name'],
        // rating: courseData['rating'],
        // totalNumberRating: courseData['number_of_ratings'],
        numberOfEnrollment: courseData['total_enrollment'],
        shareableLink: courseData['shareable_link'],
        // courseOverviewProvider: courseData['course_overview_provider'],
        // courseOverviewUrl: courseData['video_url'],
        courseCompletion: courseData['completion'],
        totalNumberOfLessons: courseData['total_number_of_lessons'],
        totalNumberOfCompletedLessons:
            courseData['total_number_of_completed_lessons'],
        enableDripContent: courseData['enable_drip_content'],
        total_reviews: courseData['total_reviews'],
        average_rating: courseData['average_rating'],
      ));
      // print(catData['name']);
    }
    return loadedCourses;
  }

  Future<void> fetchCourseSections(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/sections?course_id=$courseId';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });
      final extractedData = json.decode(response.body) as List;
      if (extractedData.isEmpty) {
        return;
      }

      final List<Section> loadedSections = [];
      for (var sectionData in extractedData) {
        loadedSections.add(Section(
          id: sectionData['id'],
          numberOfCompletedLessons: sectionData['completed_lesson_number'],
          title: sectionData['title'],
          totalDuration: sectionData['total_duration'],
          lessonCounterEnds: sectionData['lesson_counter_ends'],
          lessonCounterStarts: sectionData['lesson_counter_starts'],
          mLesson: buildSectionLessons(sectionData['lessons'] as List<dynamic>),
        ));
      }
      _sectionItems = loadedSections;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  List<Lesson> buildSectionLessons(List extractedLessons) {
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

  Future<void> toggleLessonCompleted(int lessonId, int progress) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/save_course_progress?lesson_id=$lessonId';
    // print(url);
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final responseData = json.decode(response.body);
      if (responseData['course_id'] != null) {
        final myCourse = findById(responseData['course_id']);
        myCourse.courseCompletion = responseData['course_progress'];
        myCourse.totalNumberOfCompletedLessons =
            responseData['number_of_completed_lessons'];

        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateDripContendLesson(
      int courseId, int courseProgress, int numberOfCompletedLessons) async {
    final myCourse = findById(courseId);
    myCourse.courseCompletion = courseProgress;
    myCourse.totalNumberOfCompletedLessons = numberOfCompletedLessons;

    notifyListeners();
  }

  Future<void> getEnrolled(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    var url =
        '$baseUrl/api/enroll_free_course?course_id=$courseId&auth_token=$authToken';
    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);
      if (responseData == null) {
        return;
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // Find a lesson by its ID across all sections
  Lesson? findLessonById(int lessonId) {
    for (var section in _sectionItems) {
      if (section.mLesson != null && section.mLesson!.isNotEmpty) {
        for (var lesson in section.mLesson!) {
          if (lesson.id == lessonId) {
            return lesson;
          }
        }
      }
    }
    return null; // Return null if lesson not found
  }
}

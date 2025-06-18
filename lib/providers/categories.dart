// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/all_category.dart';
import '../models/category.dart';
import '../constants.dart';
import '../models/category_detail.dart';
import '../models/course.dart';
import '../models/sub_category.dart';

class Categories with ChangeNotifier {
  List<Category> _items = [];
  List<SubCategory> _subItems = [];
  List<AllCategory> _allItems = [];
  List<CategoryDetail> _categoryDetailsitems = [];
  
  // API call management
  Timer? _debounceTimer;
  http.Client? _httpClient;
  bool _isLoadingCategories = false;

  Categories() {
    _httpClient = http.Client();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  List<Category> get items {
    return [..._items];
  }

  List<SubCategory> get subItems {
    return [..._subItems];
  }

  List<AllCategory> get allItems {
    return [..._allItems];
  }

  CategoryDetail get getCategoryDetail {
    return _categoryDetailsitems.first;
  }

  Future<void> fetchCategories() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingCategories) {
      return;
    }
    
    _isLoadingCategories = true;
    
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    // Add a small delay to debounce rapid calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      var url = '$baseUrl/api/categories';
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
          
          final List<Category> loadedCategories = [];

          for (var catData in extractedData) {
            loadedCategories.add(Category(
              id: catData['id'],
              title: catData['title'],
              thumbnail: catData['thumbnail'],
              numberOfCourses: catData['number_of_courses'],
              numberOfSubCategories: catData['number_of_sub_categories'],
            ));
          }
          
          _items = loadedCategories;
          notifyListeners();
        } else {
          throw Exception('Failed to load categories: ${response.statusCode}');
        }
      } catch (error) {
        print('Error fetching categories: $error');
        rethrow;
      } finally {
        _isLoadingCategories = false;
      }
    });
  }

  Future<void> fetchSubCategories(int catId) async {
    var url = '$baseUrl/api/sub_categories/$catId';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body) as List;
      
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      final List<SubCategory> loadedCategories = [];

      for (var catData in extractedData) {
        loadedCategories.add(SubCategory(
          id: catData['id'],
          title: catData['title'],
          parentId: catData['parent_id'],
          thumbnail: catData['thumbnail'],
          numberOfCourses: catData['number_of_courses'],
        ));

        // print(catData['name']);
      }
      _subItems = loadedCategories;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchAllCategory() async {
    var url = '$baseUrl/api/all_categories';
    try {
      final response = await http.get(Uri.parse(url));

      // Print the response body for debugging
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load categories');
      }

      if (response.body == null || response.body.isEmpty) {
        throw Exception('Response body is null or empty');
      }

      final extractedData = json.decode(response.body);

      // Check if extractedData is not null and is a List
      if (extractedData == null) {
        throw Exception('Extracted data is null');
      }

      if (extractedData is! List<dynamic>) {
        throw Exception('Extracted data is not a List');
      }

      final List<AllCategory> loadedCategories = [];

      for (var catData in extractedData) {
        if (catData == null) {
          continue; // Skip null category data
        }
        // Check if 'sub_categories' key exists and is not null
        List<dynamic> subCategories = catData['childs'] ?? [];
        loadedCategories.add(AllCategory(
          id: catData['id'],
          title: catData['title'],
          subCategory: buildSubCategory(subCategories),
          
        ));
         print(catData['id']);
         print(catData['title']);
         print(subCategories);
      }
     
      _allItems = loadedCategories;
      notifyListeners();
    } catch (error) {
      print('Error: $error');
      rethrow;
    }
  }

  List<AllSubCategory> buildSubCategory(List extractedSubCategory) {
    final List<AllSubCategory> loadedSubCategories = [];

    for (var subData in extractedSubCategory) {
      if (subData == null) {
        continue;
      }
      loadedSubCategories.add(AllSubCategory(
        id: subData['id'],
        title: subData['title'],
      ));
    }
    return loadedSubCategories;
  }

  Future<void> fetchCategoryDetails(int categoryId) async {
    var url = '$baseUrl/api/category_details?category_id=$categoryId';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body) as List;
      if (extractedData.isEmpty) {
        return;
      }

      final List<CategoryDetail> loadedCategoryDetails = [];
      for (var courseData in extractedData) {
        loadedCategoryDetails.add(CategoryDetail(
          mSubCategory: buildSubCategoryList(
              courseData['sub_categories'] as List<dynamic>),
          mCourse: buildCourseList(courseData['courses'] as List<dynamic>),
        ));
      }

      _categoryDetailsitems = loadedCategoryDetails;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  List<SubCategory> buildSubCategoryList(List extractedSubCategory) {
    final List<SubCategory> loadedSubCategories = [];

    for (var subData in extractedSubCategory) {
      loadedSubCategories.add(SubCategory(
        id: subData['id'],
        title: subData['title'],
        parentId: subData['parent_id'],
        thumbnail: subData['thumbnail'],
        numberOfCourses: subData['number_of_courses'],
      ));
    }
    // print(loadedLessons.first.title);
    return loadedSubCategories;
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
        isPaid: courseData['is_paid'],
        instructor: courseData['instructor_name'],
        instructorImage: courseData['instructor_image'],
        // rating: courseData['rating'],
        // totalNumberRating: courseData['number_of_ratings'],
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


}

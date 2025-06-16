import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/common_functions.dart';
import 'course_detail.dart';

class InstructorScreen extends StatefulWidget {
  static const routeName = '/instructor-detail';

  final String? instructorId;
  final String? instructorName;
  final String? instructorImage;

  const InstructorScreen({
    Key? key,
    this.instructorId,
    this.instructorName,
    this.instructorImage,
  }) : super(key: key);

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _instructorData = {};
  List<dynamic> _instructorCourses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInstructorDetails();
  }

  Future<void> _fetchInstructorDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // If we don't have an instructor ID or name, show an error
      if ((widget.instructorId == null || widget.instructorId!.isEmpty) && 
          (widget.instructorName == null || widget.instructorName!.isEmpty)) {
        setState(() {
          _error = 'Instructor information is not available';
          _isLoading = false;
        });
        return;
      }
      
      // Get the auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      // Fetch instructor details - use name if ID is not available
      final queryParam = widget.instructorId != null && widget.instructorId!.isNotEmpty
          ? 'instructor_id=${widget.instructorId}'
          : 'instructor_name=${Uri.encodeComponent(widget.instructorName!)}';
          
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor_details?$queryParam'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true) {
          final instructorData = data['instructor'] ?? {};
          final courses = data['courses'] ?? [];
          
          // Calculate total enrollment by summing up enrollments from all courses
          int totalStudents = 0;
          for (var course in courses) {
            if (course['total_enrollment'] != null) {
              try {
                totalStudents += int.parse(course['total_enrollment'].toString());
              } catch (e) {
                // If parsing fails, try to use the value as is
                if (course['total_enrollment'] is int) {
                  totalStudents += course['total_enrollment'] as int;
                }
              }
            }
          }
          
          // Update instructor data with calculated values
          instructorData['total_students'] = totalStudents;
          instructorData['total_courses'] = courses.length;
          
          setState(() {
            _instructorData = instructorData;
            _instructorCourses = courses;
            _isLoading = false;
          });
        } else {
          // If API returns error but we have instructor name, create a basic profile
          if (widget.instructorName != null && widget.instructorName!.isNotEmpty) {
            setState(() {
              _instructorData = {
                'name': widget.instructorName,
                'image': widget.instructorImage,
                'bio': 'No detailed biography available for this instructor.',
                'education': [],
                'expertise': [],
                'total_students': 0,
                'total_courses': 0,
                'rating': 0.0,
              };
              _isLoading = false;
            });
            
            // Try to fetch instructor's courses separately
            _fetchInstructorCourses();
          } else {
            setState(() {
              _error = data['message'] ?? 'Failed to load instructor details';
              _isLoading = false;
            });
          }
        }
      } else {
        // If server error but we have instructor name, create a basic profile
        if (widget.instructorName != null && widget.instructorName!.isNotEmpty) {
          setState(() {
            _instructorData = {
              'name': widget.instructorName,
              'image': widget.instructorImage,
              'bio': 'No detailed biography available for this instructor.',
              'education': [],
              'expertise': [],
              'total_students': 0,
              'total_courses': 0,
              'rating': 0.0,
            };
            _isLoading = false;
          });
          
          // Try to fetch instructor's courses separately
          _fetchInstructorCourses();
        } else {
          setState(() {
            _error = 'Server error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // If exception but we have instructor name, create a basic profile
      if (widget.instructorName != null && widget.instructorName!.isNotEmpty) {
        setState(() {
          _instructorData = {
            'name': widget.instructorName,
            'image': widget.instructorImage,
            'bio': 'No detailed biography available for this instructor.',
            'education': [],
            'expertise': [],
            'total_students': 0,
            'total_courses': 0,
            'rating': 0.0,
          };
          _isLoading = false;
        });
        
        // Try to fetch instructor's courses separately
        _fetchInstructorCourses();
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // Separate method to fetch instructor courses if main API fails
  Future<void> _fetchInstructorCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      // Use instructor ID if available, otherwise use name
      final queryParam = widget.instructorId != null && widget.instructorId!.isNotEmpty
          ? 'instructor_id=${widget.instructorId}'
          : 'instructor_name=${Uri.encodeComponent(widget.instructorName!)}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor_courses?$queryParam'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['courses'] != null) {
          final courses = data['courses'];
          
          // Calculate total enrollment by summing up enrollments from all courses
          int totalStudents = 0;
          for (var course in courses) {
            if (course['total_enrollment'] != null) {
              try {
                totalStudents += int.parse(course['total_enrollment'].toString());
              } catch (e) {
                // If parsing fails, try to use the value as is
                if (course['total_enrollment'] is int) {
                  totalStudents += course['total_enrollment'] as int;
                }
              }
            }
          }
          
          setState(() {
            _instructorCourses = courses;
            // Update instructor data with calculated values
            _instructorData['total_students'] = totalStudents;
            _instructorData['total_courses'] = courses.length;
          });
        }
      }
    } catch (e) {
      print('Error fetching instructor courses: $e');
      // Don't set error state here, just log the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBarOne(
        title: widget.instructorName ?? 'Instructor Profile',
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
        : _error != null
          ? _buildErrorView()
          : _buildInstructorProfile(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading instructor details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchInstructorDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorProfile() {
    // Use provided data or fallback to fetched data
    final name = widget.instructorName ?? _instructorData['name'] ?? 'Instructor';
    final image = widget.instructorImage ?? _instructorData['image'];
    final bio = _instructorData['bio'] ?? 'No biography available for this instructor.';
    final expertise = _instructorData['expertise'] ?? [];
    final education = _instructorData['education'] ?? [];
    final totalStudents = _instructorData['total_students'] ?? 0;
    final totalCourses = _instructorData['total_courses'] ?? _instructorCourses.length;
    final rating = _instructorData['rating'] ?? 0.0;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructor header card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // Instructor avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: image != null && image.toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  image.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        name.toString()[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(
                                  name.toString()[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(width: 16),
                        // Instructor info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_instructorData['title'] != null)
                                Text(
                                  _instructorData['title'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Total enrollment with icon - similar to home screen
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 14,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalStudents students enrolled',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF10B981),
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
                  
                  // Stats section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Students count
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                totalStudents.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const Text(
                                'Students',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Courses count
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                totalCourses.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const Text(
                                'Courses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rating
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFFFA000),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const Text(
                                'Rating',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
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
            
            const SizedBox(height: 24),
            
            // Biography section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Biography',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  
                  // Education section if available
                  if (education.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Education',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...education.map((edu) => _buildEducationItem(edu)).toList(),
                  ],
                  
                  // Expertise section if available
                  if (expertise.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Expertise',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expertise.map<Widget>((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            skill.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Courses section
            if (_instructorCourses.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Courses by this Instructor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              
              // Course list - using category details style
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _instructorCourses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(_instructorCourses[index]);
                },
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No courses available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This instructor hasn\'t published any courses yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEducationItem(dynamic education) {
    final String degree = education['degree'] ?? '';
    final String institution = education['institution'] ?? '';
    final String year = education['year'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              size: 16,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  institution,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (year.isNotEmpty)
                  Text(
                    year,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final name = widget.instructorName ?? _instructorData['name'] ?? 'Instructor';
    final image = widget.instructorImage ?? _instructorData['image'] ?? '';
    final totalEnrollment = course['total_enrollment'] ?? 0;
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          CourseDetailScreen.routeName,
          arguments: course['id'],
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Title Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                course['title'] ?? 'Course Title',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            
            // Thumbnail Section
            CachedNetworkImage(
              imageUrl: course['thumbnail'] ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
            
            // Course Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructor Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            course['instructor_image'] ?? image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              color: Color(0xFF6366F1),
                              size: 24,
                            ),
                          ),
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
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              course['instructor_name'] ?? name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Stats Row - Only showing students count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalEnrollment students',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Price
                  if (course['is_paid'] == 1 && course['price'] != null)
                    Text(
                      course['price'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        fontFamily: 'Inter',
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../constants.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/course_list_item.dart';

class CoursesScreen extends StatefulWidget {
  static const routeName = '/courses';
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      final routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      final pageDataType = routeArgs['type'] as CoursesPageData;
      if (pageDataType == CoursesPageData.category) {
        final categoryId = routeArgs['category_id'] as int;
        Provider.of<Courses>(context)
            .fetchCoursesByCategory(categoryId)
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else if (pageDataType == CoursesPageData.search) {
        final searchQuery = routeArgs['search_query'] as String;
        Provider.of<Courses>(context)
            .fetchCoursesBySearchQuery(searchQuery)
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else if (pageDataType == CoursesPageData.all) {
        Provider.of<Courses>(context)
            .filterCourses('all', 'all', 'all', 'all', 'all')
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseData = Provider.of<Courses>(context, listen: false).items;
    final courseCount = courseData.length;
    
    return Scaffold(
      appBar: const AppBarOne(title: 'Courses'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : Container(
              color: const Color(0xFFF8F9FA),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Showing $courseCount Courses',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Explore our collection of courses',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Courses List
                      AnimationLimiter(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: courseData.length,
                          itemBuilder: (ctx, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: CourseListItem(
                                    id: courseData[index].id,
                                    title: courseData[index].title.toString(),
                                    thumbnail: courseData[index].thumbnail.toString(),
                                    price: courseData[index].price.toString(),
                                    instructor: courseData[index].instructor.toString(),
                                    average_rating: courseData[index].average_rating.toString(),
                                    total_reviews: courseData[index].total_reviews,
                                    numberOfEnrollment: courseData[index].numberOfEnrollment,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

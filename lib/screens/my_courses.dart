import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:math';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../widgets/my_course_grid.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: Theme.of(context).colorScheme.background,
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () async {
            await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const SizedBox(height: 16),
                  _buildCoursesStatus(),
                  const SizedBox(height: 20),
                  courseView(),
                  const SizedBox(height: 20),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesStatus() {
    return Consumer<MyCourses>(
      builder: (context, myCourseData, _) {
        // Calculate average progress across all courses
        double averageProgress = 0;
        int totalCompletedLessons = 0;
        int totalLessons = 0;
        
        if (myCourseData.items.isNotEmpty) {
          for (var course in myCourseData.items) {
            averageProgress += (course.courseCompletion ?? 0);
            totalCompletedLessons += (course.totalNumberOfCompletedLessons ?? 0);
            totalLessons += (course.totalNumberOfLessons ?? 0);
          }
          averageProgress = averageProgress / myCourseData.items.length;
        }
        
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${myCourseData.items.length} Courses',
                    style: const TextStyle(
                          fontSize: 20,
                      fontWeight: FontWeight.bold,
                          color: Colors.white,
                    ),
                  ),
                      const SizedBox(height: 5),
                  const Text(
                    'Continue your learning journey',
                    style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to the first course or most recent one
                      if (myCourseData.items.isNotEmpty) {
                        // Handle navigation
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Progress section
              if (myCourseData.items.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${averageProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: averageProgress / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  progressColor: Colors.white,
                  barRadius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 1000,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertificateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Certificate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/certificate.png', // Ensure this asset exists
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed on May 24, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle download or share
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget courseView() {
    final height = MediaQuery.of(context).size.height - 
                   MediaQuery.of(context).padding.top - 
                   kToolbarHeight - 150;
    
    return FutureBuilder(
      future: Provider.of<MyCourses>(context, listen: false).fetchMyCourses(),
      builder: (ctx, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CupertinoActivityIndicator(color: Color(0xFF6366F1)),
            ),
          );
        } else {
          if (dataSnapshot.error != null) {
            return SizedBox(
              height: height,
              child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Something went wrong while loading courses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Error details: ${dataSnapshot.error.toString().substring(0, min(100, dataSnapshot.error.toString().length))}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12, 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
              ),
            );
          } else {
            return Consumer<MyCourses>(
              builder: (context, myCourseData, child) {
                try {
                if (myCourseData.items.isEmpty) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 80,
                            color: const Color(0xFF6366F1).withOpacity(0.7),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No courses yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Explore and enroll in courses to get started',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Navigate to explore courses screen
                            },
                            child: const Text('Explore Courses'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                  // Safely splitting courses into In Progress and Completed
                final inProgressCourses = myCourseData.items
                    .where((course) => (course.courseCompletion ?? 0) < 100)
                    .toList();
                    
                final completedCourses = myCourseData.items
                    .where((course) => (course.courseCompletion ?? 0) == 100)
                    .toList();
                
                return DefaultTabController(
                  length: 2,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          labelColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          dividerHeight: 0,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Icon(Icons.play_circle_outline_rounded),
                                  const SizedBox(width: 8),
                                  Text(
                                    "In Progress (${inProgressCourses.length})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                              fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Icon(Icons.check_circle_outline_rounded),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Completed (${completedCourses.length})",
                                    style: const TextStyle(
                              fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Bar View
                      Container(
                        constraints: BoxConstraints(
                          minHeight: 250,
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: TabBarView(
                          children: [
                            // In Progress Courses Tab
                            inProgressCourses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline_rounded,
                                          size: 60,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No courses in progress',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Padding(
                                        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                                      child: AlignedGridView.count(
                                        shrinkWrap: true,
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: inProgressCourses.length,
                                        itemBuilder: (ctx, index) {
                                          return MyCourseGrid(
                                            myCourse: inProgressCourses[index],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  
                            // Completed Courses Tab
                            completedCourses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 60,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No completed courses yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Padding(
                                        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                                        child: Column(
                                          children: [
                                            // Remove certificate card
                                            AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                                        itemCount: completedCourses.length,
                  itemBuilder: (ctx, index) {
                    return MyCourseGrid(
                                            myCourse: completedCourses[index],
                    );
                  },
                    ),
                                          ],
                                        ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                  ],
                  ),
                );
                } catch (e) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Error occurred: $e',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          }
        }
      },
    );
  }
}
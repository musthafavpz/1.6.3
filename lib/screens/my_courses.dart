import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../widgets/my_course_grid.dart';
import 'dart:ui';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});
  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  String _currentFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final List<String> _filterOptions = ['All', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeFilter(String filter) {
    if (_currentFilter != filter) {
      setState(() {
        _currentFilter = filter;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: kBackGroundColor,
        child: RefreshIndicator(
          color: kDefaultColor,
          onRefresh: () async {
            await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildFilterTabs(),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: courseView(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Courses',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Consumer<MyCourses>(
            builder: (ctx, myCourseData, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kDefaultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${myCourseData.items.length} Courses',
                style: TextStyle(
                  color: kDefaultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _currentFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelected ? kDefaultColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget courseView() {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        200;
    
    return FutureBuilder(
      future: Provider.of<MyCourses>(context, listen: false).fetchMyCourses(),
      builder: (ctx, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CupertinoActivityIndicator(color: kDefaultColor),
            ),
          );
        } else if (dataSnapshot.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  'Error: ${dataSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDefaultColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          return Consumer<MyCourses>(
            builder: (context, myCourseData, child) {
              // Filter courses based on selected filter
              final filteredCourses = _currentFilter == 'All'
                  ? myCourseData.items
                  : myCourseData.items.where((course) {
                      // Assuming course has a property like 'progress' or 'status'
                      // Modify this based on your actual data model
                      final bool isCompleted = course.progress == 100; // Adjust based on your model
                      return _currentFilter == 'Completed' ? isCompleted : !isCompleted;
                    }).toList();

              if (filteredCourses.isEmpty) {
                return SizedBox(
                  height: height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentFilter == 'Completed'
                              ? Icons.check_circle_outline
                              : Icons.book_outlined,
                          size: 70,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _currentFilter == 'All'
                              ? 'No courses found'
                              : _currentFilter == 'Completed'
                                  ? 'No completed courses yet'
                                  : 'No courses in progress',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Course statistics cards
                  if (_currentFilter == 'All')
                    _buildStatisticsCards(myCourseData.items),
                  
                  // Grid view of courses
                  AlignedGridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCourses.length,
                    itemBuilder: (ctx, index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0.0,
                              (1 - Curves.easeOutQuad.transform(
                                      _animationController.value)) *
                                  20,
                            ),
                            child: Opacity(
                              opacity: _animationController.value,
                              child: child,
                            ),
                          );
                        },
                        child: MyCourseGrid(
                          myCourse: filteredCourses[index],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }

  Widget _buildStatisticsCards(List courses) {
    // Calculate statistics
    final completedCourses = courses.where((course) => course.progress == 100).length;
    final inProgressCourses = courses.length - completedCourses;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'In Progress',
              inProgressCourses,
              Colors.orange,
              Icons.access_time_rounded,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              'Completed',
              completedCourses,
              Colors.green,
              Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

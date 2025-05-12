import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../widgets/my_course_grid.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text(
          'My Courses',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF6366F1)),
            onPressed: () {
              // Add search functionality here
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF6366F1)),
            onPressed: () {
              // Add filter functionality here
            },
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFFF8F9FA),
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () async {
            await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
          },
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
    );
  }

  Widget _buildCoursesStatus() {
    return Consumer<MyCourses>(
      builder: (context, myCourseData, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${myCourseData.items.length} Courses',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Continue your learning journey',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                radius: 24,
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Error occurred: ${dataSnapshot.error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return Consumer<MyCourses>(
              builder: (context, myCourseData, child) {
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
                          const Text(
                            'No courses yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Explore and enroll in courses to get started',
                            textAlign: TextAlign.center,
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
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
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Learning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AlignedGridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myCourseData.items.length,
                      itemBuilder: (ctx, index) {
                        return MyCourseGrid(
                          myCourse: myCourseData.items[index],
                        );
                      },
                    ),
                  ],
                );
              },
            );
          }
        }
      },
    );
  }
}

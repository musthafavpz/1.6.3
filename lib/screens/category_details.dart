import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants.dart';
import '../providers/categories.dart';
import '../widgets/appbar_one.dart';
import 'courses_screen.dart';
import 'sub_category.dart';

class CategoryDetailsScreen extends StatefulWidget {
  static const routeName = '/sub-cat';
  const CategoryDetailsScreen({super.key});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final categoryId = routeArgs['category_id'] as int;
    final title = routeArgs['title'];
    
    return Scaffold(
      backgroundColor: kBackGroundColor,
      appBar: AppBarOne(title: title),
      body: SafeArea(
        child: FutureBuilder(
          future: Provider.of<Categories>(context, listen: false).fetchCategoryDetails(categoryId),
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShimmer();
            } else if (dataSnapshot.error != null) {
              return _buildErrorView();
            } else {
              return _buildContent(categoryId, title);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 130,
                  height: 18,
                  color: Colors.white,
                ),
                Container(
                  width: 70,
                  height: 18,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 18,
                  color: Colors.white,
                ),
                Container(
                  width: 80,
                  height: 18,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 14)),
            style: TextButton.styleFrom(
              foregroundColor: kDefaultColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(int categoryId, String title) {
    return Consumer<Categories>(
      builder: (context, categoryDetails, child) {
        final loadedCategoryDetail = categoryDetails.getCategoryDetail;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(
                'Sub Categories',
                'Show all',
                () {
                  Navigator.of(context).pushNamed(
                    SubCategoryScreen.routeName,
                    arguments: {
                      'category_id': categoryId,
                      'title': title,
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSubCategoriesList(loadedCategoryDetail),
              const SizedBox(height: 24),
              _buildSectionHeader(
                'Courses',
                'All courses',
                () {
                  Navigator.of(context).pushNamed(
                    CoursesScreen.routeName,
                    arguments: {
                      'category_id': null,
                      'seacrh_query': null,
                      'type': CoursesPageData.all,
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCoursesGrid(loadedCategoryDetail),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,  // Reduced from 20
            fontWeight: FontWeight.w500,  // Reduced from 600
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: kSignUpTextColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 13,  // Reduced from 16
                  fontWeight: FontWeight.w400,  // Reduced from 500
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,  // Reduced from 14
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubCategoriesList(dynamic loadedCategoryDetail) {
    return SizedBox(
      height: 100,  // Reduced from 110
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: loadedCategoryDetail.mSubCategory!.length,
        itemBuilder: (ctx, index) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.1 * index, 0.1 * index + 0.5, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.1 * index, 0.1 * index + 0.5, curve: Curves.easeOut),
                ),
              ),
              child: _buildSubCategoryCard(loadedCategoryDetail, index),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSubCategoryCard(dynamic loadedCategoryDetail, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          CoursesScreen.routeName,
          arguments: {
            'category_id': loadedCategoryDetail.mSubCategory![index].id,
            'search_query': null,
            'type': CoursesPageData.category,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: MediaQuery.of(context).size.width * 0.45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),  // Reduced from 16
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),  // Reduced opacity
              blurRadius: 10,  // Reduced from 15
              offset: const Offset(0, 4),  // Reduced from 5
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),  // Reduced from 12
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),  // Reduced from 12
                child: CachedNetworkImage(
                  imageUrl: loadedCategoryDetail.mSubCategory![index].thumbnail.toString(),
                  placeholder: (context, url) => Container(
                    height: 60,  // Reduced from 70
                    width: 60,   // Reduced from 70
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 16,  // Reduced from 20
                        height: 16,  // Reduced from 20
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kDefaultColor,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 60,  // Reduced from 70
                    width: 60,   // Reduced from 70
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey, size: 18),  // Reduced from default
                  ),
                  height: 60,  // Reduced from 70
                  width: 60,   // Reduced from 70
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),  // Reduced from 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loadedCategoryDetail.mSubCategory![index].title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,  // Reduced from 14
                        fontWeight: FontWeight.w500,  // Reduced from 600
                        height: 1.2,  // Added for better line spacing
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),  // Reduced from 8,4
                      decoration: BoxDecoration(
                        color: kDefaultColor.withOpacity(0.08),  // Reduced opacity
                        borderRadius: BorderRadius.circular(8),  // Reduced from 12
                      ),
                      child: Text(
                        "${loadedCategoryDetail.mSubCategory![index].numberOfCourses.toString()} Courses",
                        style: TextStyle(
                          color: kDefaultColor,
                          fontSize: 9,  // Reduced from 10
                          fontWeight: FontWeight.w500,  // Reduced from 600
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCoursesGrid(dynamic loadedCategoryDetail) {
    return AlignedGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      itemCount: loadedCategoryDetail.mCourse!.length,
      mainAxisSpacing: 14,  // Reduced from 16
      crossAxisSpacing: 14,  // Reduced from 16
      itemBuilder: (ctx, index) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(0.05 * index, 0.05 * index + 0.5, curve: Curves.easeOut),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.05 * index, 0.05 * index + 0.5, curve: Curves.easeOut),
              ),
            ),
            child: _buildCourseCard(loadedCategoryDetail, index),
          ),
        );
      },
    );
  }
  
  Widget _buildCourseCard(dynamic loadedCategoryDetail, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          CourseDetailScreen.routeName,
          arguments: loadedCategoryDetail.mCourse![index].id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),  // Reduced from 16
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),  // Reduced opacity
              blurRadius: 10,  // Reduced from 15
              offset: const Offset(0, 4),  // Reduced from 5
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),  // Reduced from 16
                topRight: Radius.circular(12),  // Reduced from 16
              ),
              child: CachedNetworkImage(
                imageUrl: loadedCategoryDetail.mCourse![index].thumbnail.toString(),
                placeholder: (context, url) => AspectRatio(
                  aspectRatio: 16/9,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 20,  // Reduced from 24
                        height: 20,  // Reduced from 24
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kDefaultColor,
                        ),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => AspectRatio(
                  aspectRatio: 16/9,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey, size: 18),  // Reduced from default
                  ),
                ),
                height: 100,  // Reduced from 120
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),  // Reduced from 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,  // Reduced from 42
                    child: Text(
                      loadedCategoryDetail.mCourse![index].title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,  // Reduced from 15
                        fontWeight: FontWeight.w500,  // Reduced from 600
                        height: 1.2,  // Adjusted from 1.3
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),  // Reduced from 10
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: kStarColor,
                        size: 14,  // Reduced from 16
                      ),
                      const SizedBox(width: 3),  // Reduced from 4
                      Text(
                        loadedCategoryDetail.mCourse![index].average_rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,  // Reduced from 14
                          fontWeight: FontWeight.w500,  // Reduced from 600
                        ),
                      ),
                      const SizedBox(width: 4),  // Reduced from 6
                      Text(
                        '(${loadedCategoryDetail.mCourse![index].total_reviews})',
                        style: const TextStyle(
                          fontSize: 11,  // Reduced from 12
                          fontWeight: FontWeight.w400,
                          color: kGreyLightColor,
                        ),
                      ),
                    ],
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
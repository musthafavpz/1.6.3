import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/categories.dart';
import '../widgets/common_functions.dart';
import 'category_details.dart';

class ExploreScreen extends StatefulWidget {
  static const routeName = '/explore';
  
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  var _isInit = true;
  // final searchController = TextEditingController(); // Search controller no longer needed
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // searchController.dispose(); // Search controller no longer needed
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {});
      Provider.of<Categories>(context, listen: false).fetchCategories();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> refreshList() async {
    try {
      setState(() {});
      await Provider.of<Categories>(context, listen: false).fetchCategories();
    } catch (error) {
      const errorMsg = 'Could not refresh categories!';
      // ignore: use_build_context_synchronously
      CommonFunctions.showErrorDialog(errorMsg, context);
    }
  }

  // _buildHeader() removed
  // _buildFeaturedCategories() removed

  Widget _buildCategoryItem(dynamic category) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          CategoryDetailsScreen.routeName,
          arguments: {
            'category_id': category.id,
            'title': category.title,
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // Increased bottom margin
        padding: const EdgeInsets.all(12), // Added padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // More rounded corners
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2), // Softer border color
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Softer shadow
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 60, // Increased size
              width: 60,  // Increased size
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // More rounded corners
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
                )
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/loading_animated.gif',
                  image: category.thumbnail.toString(),
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) => Container(
                     color: Colors.grey.shade200,
                     child: const Icon(Icons.category_outlined, color: Colors.grey, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15), // Increased spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    category.title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16, // Increased font size
                      fontWeight: FontWeight.w600, // Bolder
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4), // Increased spacing
                  Text(
                    '${category.numberOfSubCategories} topics', // Changed wording
                    style: const TextStyle(
                      color: Colors.grey, // Standard grey
                      fontSize: 13, // Increased font size
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10), // Added spacing before icon
            Container(
              padding: const EdgeInsets.all(8), // Larger padding for icon button feel
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30), // Circular shape
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF6366F1),
                size: 16, // Adjusted size
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top; // Adjusted height calculation

    return Scaffold(
      body: Container(
        color: const Color(0xFFF8F9FA), // Consistent light background
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: refreshList,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView( // Changed to CustomScrollView for more flexible layout
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // _buildHeader() removed
                // _buildFeaturedCategories() removed
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 15), // Reduced top padding from 50 to 20
                    child: Text(
                      'All Categories',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333), // Darker text color
                      ),
                    ),
                  ),
                ),
                Consumer<Categories>(
                  builder: (context, categoriesData, child) {
                    if (categoriesData.items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: height * 0.4, // Adjusted height
                          child: const Center(
                            child: CupertinoActivityIndicator(
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20), // Consistent padding
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, index) {
                              return _buildCategoryItem(categoriesData.items[index]);
                            },
                            childCount: categoriesData.items.length,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Bottom padding for nav bar
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

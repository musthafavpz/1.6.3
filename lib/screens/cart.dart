import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academy_lms_app/models/cart_tools_model.dart';
import 'package:academy_lms_app/models/course.dart';
import 'package:academy_lms_app/providers/courses.dart';
import 'package:academy_lms_app/screens/payment_webview.dart';
import '../constants.dart';
import '../widgets/common_functions.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  CartTools? _cartTools;
  bool isLoading = false;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    fetchCartTools();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double calculateSubtotal(List<Course> courses) {
    double subtotal = 0.00;
    for (var course in courses) {
      try {
        double price = double.parse(course.price_cart.toString());
        subtotal += price;
      } catch (e) {
        print('Invalid price format for course: ${course.title}, price: ${course.price}');
      }
    }
    return subtotal;
  }

  double calculateTax(double subtotal, String taxRateString) {
    try {
      double taxRate = double.parse(taxRateString) / 100;
      return subtotal * taxRate;
    } catch (e) {
      print('Invalid tax rate format: $taxRateString');
      return 0.00;
    }
  }

  Future<void> fetchCartTools() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('access_token') ?? '');
    var url = '$baseUrl/api/cart_tools';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });

      if (response.statusCode == 200) {
        final extractedData = json.decode(response.body);
        if (extractedData != null) {
          _cartTools = CartTools.fromJson(extractedData);
        }
      } else {
        print('Failed to load cart tools. Status code: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> handleCheckout() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailPre = prefs.getString('email');
      final passwordPre = prefs.getString('password');
      var email = emailPre;
      var password = passwordPre;
      
      DateTime currentDateTime = DateTime.now();
      int currentTimestamp = (currentDateTime.millisecondsSinceEpoch / 1000).floor();
      
      String authToken = 'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
      final url = '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem';
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentWebView(url: url),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process checkout. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatCurrency(double amount, String position, String symbol) {
    String formattedAmount = amount.toStringAsFixed(2);
    switch (position) {
      case "right":
        return '$formattedAmount$symbol';
      case "left":
        return '$symbol$formattedAmount';
      case "right-space":
        return '$formattedAmount $symbol';
      case "left-space":
        return '$symbol $formattedAmount';
      default:
        return '$symbol$formattedAmount';
    }
  }

  void _showRemoveDialog(BuildContext context, int courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kDefaultColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 40,
                    color: kDefaultColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Remove Course',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Do you wish to remove this course from your cart?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: kGreyLightColor,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: const BorderSide(color: kGreyLightColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: kGreyLightColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDefaultColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Provider.of<Courses>(context, listen: false).toggleCart(courseId, true).then((_) {
                          fetchCartTools();
                          CommonFunctions.showSuccessToast('Course removed from cart');
                        });
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackGroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: kBlackColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: kDefaultColor),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: kDefaultColor,
            onRefresh: () async {
              await fetchCartTools();
              await Provider.of<Courses>(context, listen: false).fetchCartlist();
            },
            child: FutureBuilder(
              future: Provider.of<Courses>(context, listen: false).fetchCartlist(),
              builder: (ctx, dataSnapshot) {
                if (dataSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CupertinoActivityIndicator(
                      color: kDefaultColor,
                    ),
                  );
                } else if (dataSnapshot.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error occurred: ${dataSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDefaultColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                  return Consumer<Courses>(
                    builder: (context, cartData, child) {
                      if (cartData.items.isEmpty) {
                        return _buildEmptyCart();
                      }
                      
                      double subtotal = calculateSubtotal(cartData.items);
                      double tax = _cartTools != null
                          ? calculateTax(subtotal, _cartTools!.courseSellingTax)
                          : 0.0;
                      double total = subtotal + tax;
                      
                      return Stack(
                        children: [
                          CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${cartData.items.length} ${cartData.items.length == 1 ? 'Course' : 'Courses'} in Cart',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: kBlackColor,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          // Implement wishlist all or similar functionality
                                          CommonFunctions.showSuccessToast('All courses added to wishlist');
                                        },
                                        icon: const Icon(
                                          Icons.favorite_border,
                                          size: 18,
                                          color: kDefaultColor,
                                        ),
                                        label: const Text(
                                          'Save All',
                                          style: TextStyle(
                                            color: kDefaultColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final course = cartData.items[index];
                                    return _buildCartItem(context, course);
                                  },
                                  childCount: cartData.items.length,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: isLoading || _cartTools == null
                                    ? const Center(child: CupertinoActivityIndicator(color: kDefaultColor))
                                    : _buildOrderSummary(subtotal, tax, total),
                              ),
                              // Add extra space at the bottom for the fixed checkout button
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 100),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildCheckoutButton(total),
                          ),
                          if (isLoading)
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: kDefaultColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: kDefaultColor,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Your cart is empty',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Explore our top courses and add them to your cart to start your learning journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kDefaultColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.explore),
          onPressed: () {
            // Navigate to home screen or explore page
            Navigator.of(context).pushReplacementNamed('/home');
          },
          label: const Text(
            'Explore Courses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        // Add this to ensure proper bottom spacing with navigation bar
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, Course course) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
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
            // Course content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with overlay
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          course.thumbnail.toString(),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kDefaultColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.price.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Course details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Instructor name
                        Text(
                          'By ${course.instructor_name ?? "Unknown Instructor"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rating and reviews
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: kStarColor,
                              size: 16,
                            ),
                            Text(
                              " ${course.average_rating}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' (${course.total_reviews} Reviews)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Course details like lessons, hours
                        Row(
                          children: [
                            Icon(Icons.play_circle_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${course.total_lessons ?? '0'} lessons",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${course.total_duration ?? '0h'} total",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                color: Colors.grey[200],
                thickness: 1,
              ),
            ),
            // Action buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Save to wishlist functionality
                      Provider.of<Courses>(context, listen: false).toggleWishlist(course.id!);
                      CommonFunctions.showSuccessToast('Added to wishlist');
                    },
                    icon: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: kDefaultColor,
                    ),
                    label: const Text(
                      'Wishlist',
                      style: TextStyle(
                        color: kDefaultColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showRemoveDialog(context, course.id!);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
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

  Widget _buildOrderSummary(double subtotal, double tax, double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kDefaultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: kDefaultColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Coupon code section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kDefaultColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kDefaultColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: kDefaultColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Apply coupon logic
                      CommonFunctions.showSuccessToast('Coupon applied successfully');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDefaultColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 15,
                    color: kGreyLightColor,
                  ),
                ),
                Text(
                  formatCurrency(subtotal, _cartTools!.currencyPosition, _cartTools!.currencySymbol),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax (${_cartTools!.courseSellingTax}%)',
                  style: const TextStyle(
                    fontSize: 15,
                    color: kGreyLightColor,
                  ),
                ),
                Text(
                  formatCurrency(tax, _cartTools!.currencyPosition, _cartTools!.currencySymbol),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Add discount row conditionally if there's a discount
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discount',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '- ${formatCurrency(0.00, _cartTools!.currencyPosition, _cartTools!.currencySymbol)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatCurrency(total, _cartTools!.currencyPosition, _cartTools!.currencySymbol),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kDefaultColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 13,
                          color: kGreyLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cartTools != null
                            ? formatCurrency(total, _cartTools!.currencyPosition, _cartTools!.currencySymbol)
                            : '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kDefaultColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDefaultColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: kGreyLightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Secure Checkout',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

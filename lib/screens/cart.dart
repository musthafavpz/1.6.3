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

class _CartScreenState extends State<CartScreen> {
  CartTools? _cartTools;
  bool isLoading = false;
  final PageController _pageController = PageController();

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

  @override
  void initState() {
    super.initState();
    fetchCartTools();
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
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> handleCheckout() async {
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
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 50,
                  color: kDefaultColor,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Remove Course',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Do you wish to remove this course from your cart?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDefaultColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        CommonFunctions.showSuccessToast('Removed from cart');
                        Provider.of<Courses>(context, listen: false).toggleCart(courseId, true);
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: kBlackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: kBackGroundColor,
          child: RefreshIndicator(
            onRefresh: fetchCartTools,
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
                  return const Center(
                    child: Text('Error Occurred', style: TextStyle(fontSize: 16)),
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
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    '${cartData.items.length} ${cartData.items.length == 1 ? 'Course' : 'Courses'} in Cart',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: kGreyLightColor,
                                    ),
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
                                    ? const Center(child: CircularProgressIndicator())
                                    : _buildOrderSummary(subtotal, tax, total),
                              ),
                              // Add extra space at the bottom for the fixed checkout button
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 80),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildCheckoutButton(total),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: kDefaultColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add courses to start learning',
            style: TextStyle(
              fontSize: 16,
              color: kGreyLightColor,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDefaultColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // Navigate to courses page
              Navigator.of(context).pop();
            },
            child: const Text(
              'Browse Courses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Course course) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      course.thumbnail.toString(),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                // Course details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 12),
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
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' (${course.average_rating} Reviews)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kGreyLightColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.price.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kDefaultColor,
                          ),
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
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Save for later functionality
                      CommonFunctions.showSuccessToast('Saved for later');
                    },
                    icon: const Icon(
                      Icons.bookmark_border,
                      size: 18,
                      color: kDefaultColor,
                    ),
                    label: const Text(
                      'Save for later',
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
      padding: const EdgeInsets.all(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 16,
                    color: kGreyLightColor,
                  ),
                ),
                Text(
                  formatCurrency(subtotal, _cartTools!.currencyPosition, _cartTools!.currencySymbol),
                  style: const TextStyle(
                    fontSize: 16,
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
                    fontSize: 16,
                    color: kGreyLightColor,
                  ),
                ),
                Text(
                  formatCurrency(tax, _cartTools!.currencyPosition, _cartTools!.currencySymbol),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
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
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(double total) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: kGreyLightColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cartTools != null
                      ? formatCurrency(total, _cartTools!.currencyPosition, _cartTools!.currencySymbol)
                      : '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kDefaultColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDefaultColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

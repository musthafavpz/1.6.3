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
import 'package:academy_lms_app/screens/tab_screen.dart';
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
    final deviceSize = MediaQuery.of(context).size;
    final coursesProvider = Provider.of<Courses>(context);
    final cartCourses = coursesProvider.cartItems;

    double subtotal = calculateSubtotal(cartCourses);
    double tax = 0.00;
    double total = subtotal;

    if (_cartTools != null) {
      tax = calculateTax(subtotal, _cartTools!.tax.toString());
      total = subtotal + tax;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDefaultColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Cart items
                  Expanded(
                    child: cartCourses.isEmpty
                        ? _buildEmptyCart()
                        : _buildCartItems(cartCourses, coursesProvider),
                  ),

                  // Bottom order summary
                  if (cartCourses.isNotEmpty)
                    _buildOrderSummary(subtotal, tax, total),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kDefaultColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: kDefaultColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Looks like you haven\'t added any courses to your cart yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: kGreyLightColor,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const TabsScreen(pageIndex: 0),
                ),
              );
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDefaultColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(List<Course> cartCourses, Courses coursesProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: cartCourses.length,
      itemBuilder: (ctx, index) {
        final course = cartCourses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  course.thumbnail.toString(),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: kGreyLightColor),
                  ),
                ),
              ),
              
              // Course details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: kGreyLightColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course.instructor.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kGreyLightColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.price.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kDefaultColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Remove button
              IconButton(
                onPressed: () {
                  _showRemoveDialog(context, course.id!);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFFF5252),
                ),
                splashRadius: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(double subtotal, double tax, double total) {
    String? currencyPosition, currencySymbol;
    
    if (_cartTools != null) {
      currencyPosition = _cartTools!.currency_position;
      currencySymbol = _cartTools!.currency_symbol;
    } else {
      currencyPosition = "left";
      currencySymbol = "\$";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subtotal",
                  style: TextStyle(
                    fontSize: 14,
                    color: kGreyLightColor,
                  ),
                ),
                Text(
                  formatCurrency(subtotal, currencyPosition!, currencySymbol!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tax
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tax (${_cartTools?.tax ?? 0}%)",
                  style: const TextStyle(
                    fontSize: 14,
                    color: kGreyLightColor,
                  ),
                ),
                Text(
                  formatCurrency(tax, currencyPosition, currencySymbol),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatCurrency(total, currencyPosition, currencySymbol),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kDefaultColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Checkout button
            ElevatedButton(
              onPressed: isLoading ? null : () => handleCheckout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDefaultColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
              ),
              child: isLoading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

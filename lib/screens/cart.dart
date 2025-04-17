import 'dart:async';
import 'dart:convert';

import 'package:academy_lms_app/models/cart_tools_model.dart';
import 'package:academy_lms_app/models/course.dart';
import 'package:academy_lms_app/providers/courses.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final Color primaryColor = const Color(0xFF6C63FF); // Modern purple
  final Color secondaryColor = const Color(0xFFFFCF53); // Accent yellow
  final Color backgroundColor = const Color(0xFFF8F9FE); // Light background
  final Color textDarkColor = const Color(0xFF2D3142); // Dark text
  final Color textLightColor = const Color(0xFF9E9EB3); // Light text

  double calculateSubtotal(List<Course> courses) {
    double subtotal = 0.00;
    for (var course in courses) {
      try {
        double price = double.parse(course.price_cart.toString());
        subtotal += price;
      } catch (e) {
        debugPrint('Invalid price format for course: ${course.title}');
      }
    }
    return subtotal;
  }

  double calculateTax(double subtotal, String taxRateString) {
    try {
      double taxRate = double.parse(taxRateString) / 100;
      return subtotal * taxRate;
    } catch (e) {
      debugPrint('Invalid tax rate format: $taxRateString');
      return 0.00;
    }
  }

  Future<void> fetchUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('access_token') ?? '';

    var url = '$baseUrl/api/payment';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      debugPrint(e.toString());
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
      }
    } catch (error) {
      rethrow;
    }
    setState(() {
      isLoading = false;
    });
  }

  String formatCurrency(double amount) {
    if (_cartTools == null) return amount.toStringAsFixed(2);
    
    switch (_cartTools!.currencyPosition) {
      case "right":
        return '${amount.toStringAsFixed(2)}${_cartTools!.currencySymbol}';
      case "left":
        return '${_cartTools!.currencySymbol}${amount.toStringAsFixed(2)}';
      case "right-space":
        return '${amount.toStringAsFixed(2)} ${_cartTools!.currencySymbol}';
      case "left-space":
        return '${_cartTools!.currencySymbol} ${amount.toStringAsFixed(2)}';
      default:
        return '${_cartTools!.currencySymbol}${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        50;
        
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textDarkColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, Colors.white],
          ),
        ),
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: fetchCartTools,
          child: FutureBuilder(
            future: Provider.of<Courses>(context, listen: false).fetchCartlist(),
            builder: (ctx, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: height,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                );
              } else if (dataSnapshot.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textDarkColor,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Consumer<Courses>(
                  builder: (context, cartData, child) {
                    if (cartData.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/empty_cart.png', // Add an empty cart image to your assets
                              height: 150,
                              width: 150,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your cart is empty',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: textDarkColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add courses to continue shopping',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: textLightColor,
                              ),
                            ),
                            const SizedBox(height: 36),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Browse Courses',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    double subtotal = calculateSubtotal(cartData.items);
                    double tax = _cartTools != null 
                        ? calculateTax(subtotal, _cartTools!.courseSellingTax) 
                        : 0;
                    double total = subtotal + tax;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: Text(
                              '${cartData.items.length} Course${cartData.items.length > 1 ? 's' : ''} in Cart',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textLightColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: cartData.items.length,
                              itemBuilder: (ctx, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Slidable(
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                title: Text(
                                                  'Remove Course',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    color: textDarkColor,
                                                  ),
                                                ),
                                                content: Text(
                                                  'Do you wish to remove this course from your cart?',
                                                  style: GoogleFonts.poppins(
                                                    color: textDarkColor,
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: GoogleFonts.poppins(
                                                        color: textLightColor,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                      CommonFunctions.showSuccessToast('Removed from cart');
                                                      Provider.of<Courses>(context, listen: false)
                                                          .toggleCart(cartData.items[index].id!, true);
                                                    },
                                                    child: Text(
                                                      'Remove',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          backgroundColor: Colors.red[400]!,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Remove',
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                bottomLeft: Radius.circular(16),
                                              ),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  cartData.items[index].thumbnail.toString(),
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: secondaryColor.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          'Course',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                            color: secondaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      IconButton(
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) => AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              ),
                                                              title: Text(
                                                                'Remove Course',
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight: FontWeight.w600,
                                                                  color: textDarkColor,
                                                                ),
                                                              ),
                                                              content: Text(
                                                                'Do you wish to remove this course from your cart?',
                                                                style: GoogleFonts.poppins(
                                                                  color: textDarkColor,
                                                                ),
                                                              ),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style: GoogleFonts.poppins(
                                                                      color: textLightColor,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                    CommonFunctions.showSuccessToast('Removed from cart');
                                                                    Provider.of<Courses>(context, listen: false)
                                                                        .toggleCart(cartData.items[index].id!, true);
                                                                  },
                                                                  child: Text(
                                                                    'Remove',
                                                                    style: GoogleFonts.poppins(
                                                                      color: Colors.red,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline_rounded,
                                                          color: Colors.red[300],
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    cartData.items[index].title.toString(),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: textDarkColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: secondaryColor,
                                                        size: 16,
                                                      ),
                                                      Text(
                                                        " ${cartData.items[index].average_rating}",
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: textDarkColor,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' (${cartData.items[index].average_rating} Reviews)',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          color: textLightColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    cartData.items[index].price.toString(),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w700,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (cartData.items.isNotEmpty && !isLoading && _cartTools != null)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textLightColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        formatCurrency(subtotal),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textDarkColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Tax (${_cartTools!.courseSellingTax}%)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textLightColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '+ ${formatCurrency(tax)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textDarkColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Total',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textDarkColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        formatCurrency(total),
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        final emailPre = prefs.getString('email');
                                        final passwordPre = prefs.getString('password');
                                        var email = emailPre;
                                        var password = passwordPre;
                                        
                                        DateTime currentDateTime = DateTime.now();
                                        int currentTimestamp = (currentDateTime.millisecondsSinceEpoch / 1000).floor();
                                        
                                        String authToken = 'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
                                        final url = '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem';
                                        
                                        if (await canLaunchUrl(Uri.parse(url))) {
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        } else {
                                          throw 'Could not launch $url';
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Checkout Now',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isLoading && cartData.items.isNotEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

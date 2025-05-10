import 'package:flutter/material.dart';

const baseUrl = 'https://app.eleganceprep.com'; // Example: const BASE_URL = 'http://creativeitem.com/academy';

// Primary Colors
const kPrimaryColor = Color(0xFF6366F1);
const kPrimaryDarkColor = Color(0xFF4F46E5);
const kPrimaryLightColor = Color(0xFF818CF8);

// Secondary Colors
const kSecondaryColor = Color(0xFF10B981);
const kSecondaryDarkColor = Color(0xFF059669);
const kSecondaryLightColor = Color(0xFF34D399);

// Background Colors
const kBackgroundColor = Color(0xFFF8F9FA);
const kCardBackgroundColor = Colors.white;
const kInputBackgroundColor = Color(0xFFF3F4F6);

// Text Colors
const kTextPrimaryColor = Color(0xFF1F2937);
const kTextSecondaryColor = Color(0xFF4B5563);
const kTextLightColor = Color(0xFF9CA3AF);

// Status Colors
const kSuccessColor = Color(0xFF10B981);
const kErrorColor = Color(0xFFEF4444);
const kWarningColor = Color(0xFFF59E0B);
const kInfoColor = Color(0xFF3B82F6);

// Border Colors
const kBorderColor = Color(0xFFE5E7EB);
const kDividerColor = Color(0xFFE5E7EB);

// Shadow
const kDefaultShadow = BoxShadow(
  color: Color(0x1A000000),
  offset: Offset(0, 4),
  blurRadius: 10,
);

// Input Borders
const kDefaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: kBorderColor, width: 1),
);

const kDefaultFocusInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: kPrimaryColor, width: 2),
);

const kDefaultFocusErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: kErrorColor, width: 2),
);

// Legacy Colors (to be gradually replaced)
const kWhiteColor = Colors.white;
const kBlackColor = Colors.black;
const kGreyColor = Colors.grey;
const kGreyLightColor = Color(0xFF9CA3AF);
const kDefaultColor = kPrimaryColor;
const kSignUpTextColor = kPrimaryColor;
const kStarColor = Color(0xFFF59E0B);
const kTimeColor = kSuccessColor;
const kTimeBackColor = Color(0xFFD1FAE5);
const kLessonColor = kWarningColor;
const kLessonBackColor = Color(0xFFFEF3C7);
const kFavouriteColor = Color(0xFFFEE2E2);
const kFavouriteShadowColor = Color(0xFFEF4444);
const kRemoveIconColor = Color(0xFFF3F4F6);
const kToastTextColor = Color(0xFFF9FAFB);
const kGreenPurchaseColor = kSuccessColor;

enum CoursesPageData {
  category,
  filter,
  search,
  all,
}

const Map configs = {
  'MEETING_SDK_CLIENT_KEY': '7M6Wg3sxRP6fRudLqqskYQ',
  'MEETING_SDK_CLIENT_SECRET': 'z1NzSPndVwGqmquWnoJgza2i2R4GJOai',
};

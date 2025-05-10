import 'package:flutter/material.dart';

const baseUrl = 'https://app.eleganceprep.com'; // Example: const BASE_URL = 'http://creativeitem.com/academy';

// Primary Colors
const Color kPrimaryColor = Color(0xFF6366F1);
const Color kPrimaryDarkColor = Color(0xFF4F46E5);
const Color kPrimaryLightColor = Color(0xFF818CF8);

// Secondary Colors
const Color kSecondaryColor = Color(0xFF10B981);
const Color kSecondaryDarkColor = Color(0xFF059669);
const Color kSecondaryLightColor = Color(0xFF34D399);

// Background Colors
const Color kBackgroundColor = Color(0xFFF9FAFB);
const Color kCardBackgroundColor = Color(0xFFFFFFFF);
const Color kInputBackgroundColor = Color(0xFFF3F4F6);

// Text Colors
const Color kTextPrimaryColor = Color(0xFF1F2937);
const Color kTextSecondaryColor = Color(0xFF4B5563);
const Color kTextLightColor = Color(0xFF9CA3AF);
const Color kTextLowBlackColor = Color(0xFF6B7280);

// Status Colors
const Color kSuccessColor = Color(0xFF10B981);
const Color kErrorColor = Color(0xFFEF4444);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kInfoColor = Color(0xFF3B82F6);

// Border Colors
const Color kBorderColor = Color(0xFFE5E7EB);
const Color kBackButtonBorderColor = Color(0xFFD1D5DB);

// Shadow Colors
const Color kShadowColor = Color(0xFF000000);

// Legacy Colors (for backward compatibility)
const Color kBlueColor = Color(0xFF3B82F6);
const Color kRedColor = Color(0xFFEF4444);
const Color kGreenColor = Color(0xFF10B981);
const Color kYellowColor = Color(0xFFF59E0B);
const Color kPurpleColor = Color(0xFF8B5CF6);
const Color kPinkColor = Color(0xFFEC4899);
const Color kOrangeColor = Color(0xFFF97316);
const Color kTealColor = Color(0xFF14B8A6);
const Color kCyanColor = Color(0xFF06B6D4);
const Color kIndigoColor = Color(0xFF6366F1);
const Color kLimeColor = Color(0xFF84CC16);
const Color kAmberColor = Color(0xFFF59E0B);
const Color kBrownColor = Color(0xFF92400E);
const Color kGreyColor = Color(0xFF6B7280);
const Color kBlackColor = Color(0xFF000000);
const Color kWhiteColor = Color(0xFFFFFFFF);

// Form Colors
const Color kFormInputColor = Color(0xFF9CA3AF);
const Color kInputBoxBackGroundColor = Color(0xFFF3F4F6);
const Color kSelectItemColor = Color(0xFF1F2937);

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

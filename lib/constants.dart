import 'package:flutter/material.dart';

const baseUrl = 'https://app.eleganceprep.com'; // Example: const BASE_URL = 'http://creativeitem.com/academy';

// Primary Colors
const kPrimaryColor = Color(0xFFEC6800);
const kPrimaryDarkColor = Color(0xFFB3541E);
const kPrimaryLightColor = Color(0xFFFF9800);

// Secondary Colors
const kSecondaryColor = Color(0xFF808080);
const kSecondaryDarkColor = Color(0xFF605D5F);
const kSecondaryLightColor = Color(0xFFA09EAB);

// Background Colors
const kBackgroundColor = Color(0xFFF5F9FA);
const kCardBackgroundColor = Color(0xFFFFFFFF);
const kInputBackgroundColor = Color(0xFFF9F9F9);

// Text Colors
const kTextPrimaryColor = Color(0xFF273242);
const kTextSecondaryColor = Color(0xFF757575);
const kTextLightColor = Color(0xFF000000);
const kTextLowBlackColor = Colors.black38;

// Status Colors
const kSuccessColor = Color(0xFF2BD0A8);
const kErrorColor = Colors.red;
const kWarningColor = Color(0xFFEE9717);
const kInfoColor = Color(0xFF07C19F);

// Border Colors
const kBorderColor = Color(0xFFE0E0E0);
const kInputBorderColor = Color(0xFFC7C8CA);
const kBackButtonBorderColor = Color(0xFF8C3A11);

// Shadow Colors
const kShadowColor = Color(0xFF000000);
const kDefaultShadow = BoxShadow(
  offset: Offset(20, 10),
  blurRadius: 20,
  color: Colors.black12,
);

// Form Colors
const kFormInputColor = Color(0xFFC7C8CA);
const kInputBoxIconColor = Color(0xFFA09EAB);

// Legacy Colors (for backward compatibility)
const kWhiteColor = Colors.white;
const kBlackColor = Colors.black;
const kGreyColor = Colors.grey;
const kDarkGreyColor = Color(0xFF757575);
const kGreyLightColor = Color(0xFF605D5F);
const kDefaultColor = Color(0xFFFF9800);
const kSignUpTextColor = Color(0xFFFF9800);
const kSelectItemColor = Color(0xFF000000);

// Input Border Styles
const kDefaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: Colors.white, width: 2),
);

const kDefaultFocusInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: kPrimaryColor, width: 2),
);

const kDefaultFocusErrorBorder = OutlineInputBorder(
  borderSide: BorderSide(color: kErrorColor),
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
);

// Toast Colors
const kToastTextColor = Color(0xFFEEEEEE);

// Course Related Colors
const kStarColor = Color(0xFFFF953F);
const kTimeColor = Color(0xFF07C19F);
const kTimeBackColor = Color(0xFF13C6A5);
const kLessonColor = Color(0xFFEE9717);
const kLessonBackColor = Color(0xFFC67E13);
const kFavouriteColor = Color(0xFFF89696);
const kFavouriteShadowColor = Color(0xFFF76B6B);
const kRemoveIconColor = Color(0xFFF3F3F3);
const kGreenPurchaseColor = Color(0xFF2BD0A8);

// Category Colors
const iCardColor = Color(0xFFF4F8F9);
const iLongArrowRightColor = Color(0xFF559595);

// Meeting SDK Config
const Map configs = {
  'MEETING_SDK_CLIENT_KEY': '7M6Wg3sxRP6fRudLqqskYQ',
  'MEETING_SDK_CLIENT_SECRET': 'z1NzSPndVwGqmquWnoJgza2i2R4GJOai',
};

enum CoursesPageData {
  category,
  filter,
  search,
  all,
}

import 'package:flutter/material.dart';

const baseUrl = 'https://app.eleganceprep.com'; // Example: const BASE_URL = 'http://creativeitem.com/academy';

// list of colors that we use in our app
const kWhiteColor = Colors.white;
const kRedColor = Colors.red;
const kBlackColor = Colors.black;
const kGreenColor = Colors.green;
const kBlueColor = Color(0xFFEC6800);
// const kBrownColor = Colors.brown; 
const kGreyColor = Colors.grey;
const kYellowColor = Colors.yellow;
const kPurpleColor = Colors.purple;
const kDarkPurple = Color(0xFF6A1B9A); // Added for AI Assistant
const kLightPurple = Color(0xFF9C27B0); // Added for AI Assistant
const kOrangeColor = Color(0xFFB3541E);
const kIndigoColor = Colors.indigo;
const kPinkColor = Colors.pink;
const kTextColor = Color(0xFF273242);
const kTealColor = Colors.teal;
const kDarkGreyColor = Color(0xFF757575);
const kTextLightColor = Color(0xFF000000);
const kBackGroundColor = Color(0xFFFFFFFF);
const kBackButtonBorderColor = Color(0xFF8C3A11);
const kInputBoxBackGroundColor = Color(0xFFF9F9F9);
// const kInputBoxBackGroundColor = Color(0xFFF5F9FA);
// const kDefaultColor = Color(0xFFD458AD);
const kDefaultColor = Color(0xFFFF9800);
const kInputBoxIconColor = Color(0xFFA09EAB);
// const kGreyLightColor = Color(0xFF9F9B9E);
const kGreyLightColor = Color(0xFF605D5F);
// const kSignUpTextColor = Color(0xFFD732A4);
const kSignUpTextColor = Color(0xFFFF9800);
const kSecondaryColor = Color(0xFF808080);
const kSelectItemColor = Color(0xFF000000);

//background radial gradient
const kRadialGradientOneTextColor = Color(0xFFFF9800);
const kRadialGradientTwoTextColor = Color(0xFFEC6800);

const kStarColor = Color(0xFFFF953F);

// Color of Categories card, long arrow
const iCardColor = Color(0xFFF4F8F9);
const iLongArrowRightColor = Color(0xFF559595);

// our default Shadow
const kDefaultShadow = BoxShadow(
  offset: Offset(20, 10),
  blurRadius: 20,
  color: Colors.black12, // Black color with 12% opacity
);

const kFavouriteColor = Color(0xFFF89696);
const kFavouriteShadowColor = Color(0xFFF76B6B);

const kTimeColor = Color(0xFF07C19F);
const kTimeBackColor = Color(0xFF13C6A5);
const kLessonColor = Color(0xFFEE9717);
const kLessonBackColor = Color(0xFFC67E13);

const kRemoveIconColor = Color(0xFFF3F3F3);

//Toast color
const kToastTextColor = Color(0xFFEEEEEE);

const kDefaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: Colors.white, width: 2),
);

const kDefaultFocusInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  borderSide: BorderSide(color: kBlueColor, width: 2),
);
const kDefaultFocusErrorBorder = OutlineInputBorder(
  borderSide: BorderSide(color: kRedColor),
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
);

const kFormInputColor = Color(0xFFc7c8ca);
const kTextLowBlackColor = Colors.black38;
const kBackgroundColor = Color(0xFFF5F9FA);
const kPrimaryColor = Color(0xFFEC6800);
const kGreenPurchaseColor = Color(0xFF2BD0A8);

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

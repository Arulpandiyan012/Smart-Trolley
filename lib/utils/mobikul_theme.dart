/*
 * *
 *
 * Webkul Software.
 *
 * @package Mobikul App
 *
 * @Category Mobikul
 *
 * @author Webkul <support@webkul.com>
 *
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *
 * @license https://store.webkul.com/license.html ASL Licence
 *
 * @link https://store.webkul.com/license.html
 *
 * /
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MobiKulTheme {
  // 🟢 GLOBAL CHANGE: Switch entire app font to 'Poppins' (Blinkit Style)
  static String? fontFamily = GoogleFonts.poppins().fontFamily;
  
  static const Color primaryColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF51A130);

  // replace with client accent color
  static const Color skeletonLoaderColorLight = Color(0xFFE0E0E0);
  static const Color skeletonLoaderColorDark = Color(0xFF424242);
  static const Color appbarTextColor = Color(0xFF51A130);

  static const Color _lightPrimaryColor = Colors.white24;
  static const Color _lightPrimaryVariantColor = Colors.white;
  static const Color _lightOnPrimaryColor = Colors.black;

  static const Color _darkPrimaryColor = Colors.white24;
  static const Color _darkPrimaryVariantColor = Colors.black;
  static const Color _darkOnPrimaryColor = Colors.white;

  static final ThemeData lightTheme = ThemeData(
      highlightColor: skeletonLoaderColorLight,
      scaffoldBackgroundColor: _lightPrimaryVariantColor,
      // 🟢 1. Apply Font Globally
      fontFamily: fontFamily, 
      
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        actionsIconTheme: const IconThemeData(
          color: MobiKulTheme.appbarTextColor,
        ),
        backgroundColor: primaryColor,
        shadowColor: const Color(0xFFBDBDBD),
        titleTextStyle: TextStyle(
          color: MobiKulTheme.appbarTextColor,
          fontSize: 18,
          // 🟢 2. Apply to AppBar
          fontFamily: fontFamily, 
          fontWeight: FontWeight.w700, 
        ),
        iconTheme: const IconThemeData(color: MobiKulTheme.appbarTextColor),
      ),
      textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Color(0xFFC8E6C9), cursorColor: Colors.green),
      colorScheme: const ColorScheme.light(
        primary: _lightPrimaryColor,
        secondary: primaryColor,
        secondaryContainer: _lightPrimaryVariantColor,
        onSurface: MobiKulTheme.accentColor,
        onPrimary: Colors.black87,
      ),
      checkboxTheme: CheckboxThemeData(
        side: WidgetStateBorderSide.resolveWith(
            (states) => const BorderSide(color: accentColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      iconTheme: const IconThemeData(
        color: _lightOnPrimaryColor,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _lightOnPrimaryColor),
      
      // 🟢 3. Define Global Text Styles
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: fontFamily),
        displayMedium: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: fontFamily),
        displaySmall: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontFamily: fontFamily),
        headlineLarge: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: fontFamily),
        headlineMedium: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: fontFamily),
        headlineSmall: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: fontFamily),
        titleLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: fontFamily),
        titleMedium: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: fontFamily),
        titleSmall: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: fontFamily),
        labelLarge: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: fontFamily),
        labelMedium: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontFamily: fontFamily),
        labelSmall: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontFamily: fontFamily),
        bodyLarge: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
            fontFamily: fontFamily),
        bodyMedium: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
            fontFamily: fontFamily),
        bodySmall: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            fontFamily: fontFamily),
      ),
      dividerTheme: const DividerThemeData(color: Colors.black12),
      bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0xFF2A65B3)));

  static final ThemeData darkTheme = ThemeData(
      scaffoldBackgroundColor: _darkPrimaryVariantColor,
      highlightColor: skeletonLoaderColorDark,
      // 🟢 4. Apply to Dark Mode as well
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700),
      ),
      checkboxTheme: CheckboxThemeData(
        side: WidgetStateBorderSide.resolveWith(
            (states) => const BorderSide(color: _darkOnPrimaryColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: accentColor,
        secondaryContainer: _darkPrimaryVariantColor,
        onPrimary: Colors.white,
        onSurface: _darkOnPrimaryColor,
        surface: Colors.black,
      ),
      iconTheme: const IconThemeData(
        color: _darkOnPrimaryColor,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _darkOnPrimaryColor),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: fontFamily),
        displayMedium: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: fontFamily),
        displaySmall: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: fontFamily),
        headlineLarge: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: fontFamily),
        headlineMedium: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: fontFamily),
        headlineSmall: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: fontFamily),
        titleLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: fontFamily),
        titleMedium: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: fontFamily),
        titleSmall: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: fontFamily),
        labelLarge: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: fontFamily),
        labelMedium: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: fontFamily),
        labelSmall: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            fontFamily: fontFamily),
        bodyLarge: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            fontFamily: fontFamily),
        bodyMedium: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            fontFamily: fontFamily),
        bodySmall: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            fontFamily: fontFamily),
      ),
      dividerTheme: const DividerThemeData(color: Colors.grey),
      bottomAppBarTheme: const BottomAppBarThemeData(color: _darkOnPrimaryColor));

  Color getColor(double rating) {
    if (rating <= 1.0) {
      return const Color(0xFFE51A1A);
    } else if (rating <= 2) {
      return const Color(0xFFE91E63);
    } else if (rating <= 3) {
      return const Color(0xFFFFA100);
    } else if (rating <= 4) {
      return const Color(0xFFFFCC00);
    } else {
      return const Color(0xFF6BC700);
    }
  }
}
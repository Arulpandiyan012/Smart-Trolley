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
  static const Color accentColor = Color(0xFF27C16B);

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
    useMaterial3: true,
    highlightColor: skeletonLoaderColorLight,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Blinkit Light Grey
    primaryColor: const Color(0xFF27C16B),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF27C16B),
      secondary: const Color(0xFF27C16B),
      brightness: Brightness.light,
    ),
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
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: MobiKulTheme.appbarTextColor),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Color(0xFFC8E6C9), 
      cursorColor: Colors.green,
    ),
    checkboxTheme: CheckboxThemeData(
      side: MaterialStateBorderSide.resolveWith(
        (states) => const BorderSide(color: accentColor),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    iconTheme: const IconThemeData(
      color: _lightOnPrimaryColor,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightOnPrimaryColor,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    dividerTheme: const DividerThemeData(color: Colors.black12),
    bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0xFF2A65B3)),
  );

  static final ThemeData darkTheme = ThemeData(
      scaffoldBackgroundColor: _darkPrimaryVariantColor,
      highlightColor: skeletonLoaderColorDark,
      // 🟢 4. Apply to Dark Mode as well
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontFamily: fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.w700),
      ),
      checkboxTheme: CheckboxThemeData(
        side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(color: _darkOnPrimaryColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: accentColor,
        secondaryContainer: _darkPrimaryVariantColor,
        onPrimary: Colors.white,
        onBackground: _darkOnPrimaryColor,
        background: Colors.black,
      ),
      iconTheme: const IconThemeData(
        color: _darkOnPrimaryColor,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _darkOnPrimaryColor),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      dividerTheme: const DividerThemeData(color: Colors.grey),
      bottomAppBarTheme: const BottomAppBarThemeData(color: _darkOnPrimaryColor));

  getColor(double rating) {
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
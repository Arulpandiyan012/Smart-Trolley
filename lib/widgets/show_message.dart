/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/utils/application_localization.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

import '../utils/string_constants.dart';

class ShowMessage {
  
  // 🟢 SUCCESS
  static void successNotification(String msg, BuildContext context) {
    _showModernAlert(
      context: context,
      title: StringConstants.success.localized(),
      message: msg,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFFE8F5E9), // Soft Mint Green
      iconColor: const Color(0xFF2E7D32),       // Dark Green
      borderColor: const Color(0xFFA5D6A7),
    );
  }

  // 🔴 ERROR
  static void errorNotification(String msg, BuildContext context) {
    _showModernAlert(
      context: context,
      title: StringConstants.failed.localized(),
      message: msg,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFFFEBEE), // Soft Red
      iconColor: const Color(0xFFC62828),       // Dark Red
      borderColor: const Color(0xFFEF9A9A),
    );
  }

  // 🟡 WARNING
  static void warningNotification(String msg, BuildContext context, {String? title}) {
    _showModernAlert(
      context: context,
      title: title ?? StringConstants.warning.localized(),
      message: msg,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFFFF8E1), // Soft Amber
      iconColor: const Color(0xFFF57F17),       // Dark Amber
      borderColor: const Color(0xFFFFE082),
    );
  }

  // 🔵 GENERIC / CUSTOM
  static void showNotification(String? title, String? message, Color? color, Icon icon) {
    _showModernAlert(
      context: null, // Context not always needed for generic
      title: title ?? "",
      message: message ?? StringConstants.somethingWrong.localized(),
      icon: icon.icon ?? Icons.info_rounded,
      backgroundColor: Colors.white,
      iconColor: color ?? Colors.black87,
      borderColor: Colors.grey.shade300,
    );
  }

  // ===========================================================================
  // 🎨 MODERN FLOATING UI BUILDER
  // ===========================================================================
  static void _showModernAlert({
    required BuildContext? context,
    required String title,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color borderColor,
  }) {
    showOverlayNotification((context) {
      return SafeArea(
        child: SlideDismissible(
          key: ValueKey(message),
          direction: DismissDirection.up,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Bubble
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  
                  const SizedBox(width: 14),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: iconColor, // Title matches icon color
                            height: 1.2
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.4
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Dismiss Handle (Optional, purely visual)
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 8.0),
                  //   child: Icon(Icons.close, size: 18, color: iconColor.withOpacity(0.5)),
                  // )
                ],
              ),
            ),
          ),
        ),
      );
    }, duration: const Duration(seconds: 3));
  }
}
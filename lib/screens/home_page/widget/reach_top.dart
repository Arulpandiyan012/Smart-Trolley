// lib/screens/home_page/widget/reach_top.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact, on-brand "Back to top" pill.
/// Usage (already in your page):
/// Positioned(
///   left: 0, right: 0, bottom: 12,
///   child: buildReachBottomView(context, _scrollController),
/// )
Widget buildReachBottomView(BuildContext context, ScrollController controller) {
  final cs = Theme.of(context).colorScheme;

  return SafeArea(
    top: false,
    child: Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () async {
            HapticFeedback.selectionClick();
            await controller.animateTo(
              controller.position.minScrollExtent,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              // ✅ match your app’s green accents; falls back to theme primary
              color: cs.primary, // e.g. your 0xFF2E7D32
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // subtle soft chip for the arrow
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Back to top',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.0,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

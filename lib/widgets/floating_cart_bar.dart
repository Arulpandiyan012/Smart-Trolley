import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_global_data.dart';
import '../utils/shared_preference_helper.dart';
import '../screens/cart_screen/utils/cart_index.dart';

class FloatingCartBar extends StatelessWidget {
  final double bottomMargin;

  const FloatingCartBar({
    Key? key,
    this.bottomMargin = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: GlobalData.cartCountController.stream,
      initialData: appStoragePref.getCartCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count <= 0) return const SizedBox.shrink();

        return Positioned(
          bottom: bottomMargin + MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, cartScreen);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xE627C16B), // 90% Opacity Blinkit Green
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$count ${count == 1 ? 'Item' : 'Items'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            "View Total",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: const [
                          Text(
                            "View Cart",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_right, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

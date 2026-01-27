/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/utils/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_constants.dart';
import '../utils/app_global_data.dart';
import '../utils/badge_helper.dart';
import '../utils/shared_preference_helper.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int? index;
  const CommonAppBar(this.title, {Key? key, this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0, // 🟢 Flat modern look
      centerTitle: false, // 🟢 Align title to left like Blinkit/Zepto
      
      // 🟢 Add a subtle bottom border line instead of heavy shadow
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey[200],
          height: 1,
        ),
      ),

      // 🟢 Ensure Status Bar icons are dark
      systemOverlayStyle: SystemUiOverlayStyle.dark,

      // 🟢 Ensure Back Button is Black
      iconTheme: const IconThemeData(color: Colors.black),

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black, // 🟢 Black Text
          fontWeight: FontWeight.w700, // 🟢 Bold
          fontSize: 18, // 🟢 Modern Size
        ),
      ),
      
      actions: [
        IconButton(
            onPressed: () {
              if (index != 0) {
                Navigator.pushNamed(context, searchScreen);
              }
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black87, // 🟢 Dark Icon
              size: 24,
            )),
        IconButton(
            onPressed: () {
              if (index != 1) {
                Navigator.pushNamed(context, compareScreen);
              }
            },
            icon: const Icon(
              Icons.compare_arrows,
              color: Colors.black87, // 🟢 Dark Icon
              size: 24,
            )),
        StreamBuilder(
          stream: GlobalData.cartCountController.stream,
          builder: (BuildContext context, snapshot) {
            int count = snapshot.data ?? 0;

            appStoragePref.setCartCount(count);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: BadgeIcon(
                badgeCount: count,
                icon: IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined, 
                    color: Colors.black87, // 🟢 Dark Icon
                    size: 24
                  ),
                  onPressed: () {
                    if (index != 2) {
                      Navigator.pushNamed(context, cartScreen);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
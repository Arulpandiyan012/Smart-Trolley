/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/screens/drawer/utils/index.dart';

class DrawerAddItemList extends StatelessWidget {
  final String? headingTitle;
  final String? subTitle;
  final IconData? icon;
  final void Function()? onTap;

  const DrawerAddItemList(
      {super.key, this.headingTitle, this.subTitle, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return headingTitle != null
        ? SizedBox(
            height: 40,
            child: ListTile(
                title: Text(
              headingTitle?.localized().toUpperCase() ?? "",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.grey[600], // 🟢 FIX: Visible Grey Color
              ),
            )),
          )
        : SizedBox(
            height: 50,
            child: ListTile(
              onTap: onTap,
              leading: Icon(
                icon,
                size: AppSizes.spacingWide,
                // 🟢 FIX: Changed from 'onPrimary' (White) to Grey[700]
                color: Colors.grey[700], 
              ),
              title: Text(
                subTitle?.localized() ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87, // 🟢 FIX: Enforce Black Text
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                // 🟢 FIX: Changed from 'onPrimary' (White) to Grey[400]
                color: Colors.grey[400], 
              ),
            ),
          );
  }
}
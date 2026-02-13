/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'dart:async';
import 'package:rxdart/rxdart.dart'; // 🟢 1. ADD THIS IMPORT

import '../data_model/currency_language_model.dart';
import '../screens/cms_screen/data_model/cms_model.dart';
import '../screens/home_page/data_model/get_categories_drawer_data_model.dart';
import '../screens/home_page/data_model/new_product_data.dart';
import '../screens/cart_screen/cart_model/cart_data_model.dart';
import 'server_configuration.dart';
import 'package:flutter/material.dart'; // For debugPrint

/// Global Data class to store global data throughout the application like currency, language, cookie, etc. and stream controllers.

class GlobalData {
  static CurrencyLanguageList? languageData;
  static String? cookie;
  static String locale = defaultStoreCode;
  static String currencyCode = defaultCurrencyCode;
  static String? currencySymbol = "";
  static int rootCategoryId = 1;
  static CmsData? cmsData;
  static GetDrawerCategoriesData? categoriesDrawerData;

  // 🟢 2. CHANGE TO BehaviorSubject (Remembers the last value)
  // This ensures the Bottom Bar gets the count immediately when navigating back.
  static final BehaviorSubject<int> cartCountController =
      BehaviorSubject<int>.seeded(0);

  static StreamController<NewProductsModel?> productsStream =
      StreamController<NewProductsModel?>.broadcast();

  // 🟢 NEW: Stream to notify Cart Screen to refresh
  static StreamController<void> cartUpdateStream = StreamController<void>.broadcast();

  // 🟢 NEW: Profile Synchronization (Image, Name, etc.)
  static final BehaviorSubject<Map<String, String?>> profileUpdateStream =
      BehaviorSubject<Map<String, String?>>.seeded({});

  // 🟢 NEW: Wishlist Synchronization
  static Set<String> wishlistProductIds = {};
  static final BehaviorSubject<Set<String>> wishlistUpdateStream =
      BehaviorSubject<Set<String>>.seeded({});

  static List<NewProductsModel?>? allProducts = [];

  // 🟢 NEW: Global Cart Items Map (ProductId -> {qty: int, cartItemId: String})
  // This allows Product Cards to show + / - and update correctly.
  static final BehaviorSubject<Map<String, Map<String, dynamic>>> cartItemsController =
      BehaviorSubject<Map<String, Map<String, dynamic>>>.seeded({});
  
  // 🟢 CUSTOM RATINGS CACHE (Bypassing Bagisto Cache)
  // Map<ProductId, {rating: double, count: int}>
  static Map<String, dynamic> customRatings = {};

  // 🟢 NEW: Unitary method to update cart state across the app
  static void updateCartState(CartModel? model) {
    if (model == null) {
      cartCountController.add(0);
      cartItemsController.add({});
      return;
    }

    int count = model.itemsQty ?? 0;
    cartCountController.add(count);

    Map<String, Map<String, dynamic>> itemMap = {};
    if (model.items != null) {
      for (var item in model.items!) {
        String? pid = (item.productId ?? item.product?.id)?.toString();
        if (pid != null) {
          itemMap[pid] = {
            "qty": item.quantity ?? 0,
            "cartItemId": item.id
          };
        }
      }
    }
    cartItemsController.add(itemMap);
    debugPrint("📦 GLOBAL CART SYNC: count=$count, items=${itemMap.length}");
  }

  // 🟢 NEW: Optimistic Update for instant UI feedback
  static void optimisticUpdateCart(int productId, int delta) {
    // 1. Update Cart Items Map
    final currentMap = Map<String, Map<String, dynamic>>.from(cartItemsController.value);
    final pid = productId.toString();
    
    final info = currentMap[pid] ?? {"qty": 0, "cartItemId": null};
    int oldQty = info['qty'] ?? 0;
    int newQty = oldQty + delta;
    
    if (newQty <= 0) {
      currentMap.remove(pid);
    } else {
      currentMap[pid] = {
        "qty": newQty,
        "cartItemId": info['cartItemId']
      };
    }
    cartItemsController.add(currentMap);

    // 2. Update Total Count
    int currentCount = cartCountController.value;
    cartCountController.add(currentCount + delta);
    
    debugPrint("⚡ OPTIMISTIC CART UPDATE: pid=$pid, delta=$delta, newQty=$newQty");
  }
}

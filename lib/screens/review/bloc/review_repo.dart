/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

// ignore_for_file: file_names, avoid_print

import 'package:bagisto_app_demo/screens/review/utils/index.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';

abstract class ReviewsRepository {
  Future<ReviewModel> callReviewApi(int page);
}



class ReviewsRepositoryImp implements ReviewsRepository {
  @override
  Future<ReviewModel> callReviewApi(int page) async {
    try {
      // 🟢 CUSTOM API: Fetch My Reviews (Bypassing Standard API)
      String customerId = appStoragePref.getCustomerId().toString();
      
      final Uri url = Uri.parse("https://ecom.thesmartedgetech.com/mobikul-review-api.php?action=get_my_reviews&customer_id=$customerId");
      
      print("🚀 Fetching Reviews from Custom API: $url");
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
             print("✅ Custom Reviews Fetched: ${jsonResponse['data']?.length ?? 0}");
             
             // MAP CUSTOM JSON TO APP MODEL
             List<dynamic> rawData = jsonResponse['data'] ?? [];
             List<ReviewData> reviews = [];

             for (var item in rawData) {
               reviews.add(ReviewData(
                 id: item['id']?.toString(),
                 title: item['title'],
                 rating: int.tryParse(item['rating'].toString()) ?? 5,
                 comment: item['comment'],
                 status: item['status'],
                 createdAt: item['created_at'],
                 product: ProductData(
                   id: item['product']['id']?.toString(),
                   name: item['product']['name'],
                   urlKey: item['product']['url_key'],
                   images: [
                     Images(url: item['product']['base_image']['url'])
                   ]
                 )
               ));
             }

             return ReviewModel(
               data: reviews,
               paginatorInfo: PaginatorInfo(
                 count: reviews.length,
                 currentPage: 1,
                 lastPage: 1,
                 total: reviews.length
               )
             );
        }
      }
    } catch (error) {
      print("❌ Custom Review Fetch Error: $error");
    }
    return ReviewModel(data: []);
  }

  // 🟢 NEW: Fetch ALL Ratings for Home Page Tiles (Bypassing Cache)
  static Future<void> fetchAllRatingsMap() async {
    try {
      final Uri url = Uri.parse("https://ecom.thesmartedgetech.com/mobikul-review-api.php?action=get_all_ratings");
      print("🚀 Fetching Global Ratings Map...");
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
           List<dynamic> list = jsonResponse['data'] ?? [];
           
           // Clear existing to avoid stale
           GlobalData.customRatings.clear();
           
           for (var item in list) {
              String pid = item['product_id'].toString();
              double avg = double.tryParse(item['avg_rating'].toString()) ?? 0.0;
              int count = int.tryParse(item['count'].toString()) ?? 0;
              
              GlobalData.customRatings[pid] = {
                'rating': avg,
                'count': count
              };
           }
           print("✅ Global Ratings Map Updated: ${GlobalData.customRatings.length} products");
        }
      }
    } catch (e) {
      print("❌ Global Ratings Fetch Error: $e");
    }
  }
}

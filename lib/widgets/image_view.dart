/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

// file_names, avoid_print, must_be_immutable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/assets_constants.dart';

class ImageView extends StatelessWidget {
  final String? url;
  final double height;
  final double width;
  final BoxFit? fit;
  final String? placeHolder;

  const ImageView({
    Key? key,
    this.url,
    this.width = 0.0,
    this.height = 0.0,
    this.placeHolder,
    this.fit = BoxFit.fill,
  }) : super(key: key);

  static String normalizeUrl(String? rawUrl) {
    String cleanUrl = rawUrl?.trim() ?? "";
    if (cleanUrl.isNotEmpty && !cleanUrl.startsWith("data:")) {
       debugPrint("🖼️ Normalizing Image URL: $cleanUrl");
    }
    
    // 1. Filter out local file paths that crash CachedNetworkImage
    if (cleanUrl.startsWith("file:///")) {
      return "";
    }

    // 2. Normalize relative paths if needed
    if (cleanUrl.isNotEmpty && !cleanUrl.startsWith("http")) {
      const String baseDomain = "https://ecom.thesmartedgetech.com";
      if (cleanUrl.startsWith("/")) {
        cleanUrl = "$baseDomain$cleanUrl";
      } else {
        cleanUrl = "$baseDomain/$cleanUrl";
      }
    }
    
    // 3. Transform broken storage paths to working cache paths
    if (cleanUrl.contains("/storage/product/")) {
        cleanUrl = cleanUrl.replaceFirst("/storage/product/", "/cache/medium/product/");
    }

    // 4. Filter out known "empty" backend paths that return 500
    if (cleanUrl.endsWith("/cache/medium/product/") || 
        cleanUrl.endsWith("/storage/small/") ||
        cleanUrl.endsWith("/storage/medium/") ||
        cleanUrl.endsWith("/storage/large/")) {
        return "";
    }

    return cleanUrl;
  }

  static ImageProvider getImageProvider(String? url, {String? fallbackAsset}) {
    final cleanUrl = normalizeUrl(url);
    if (cleanUrl.isEmpty) {
      return AssetImage(fallbackAsset ?? AssetConstants.placeHolder);
    }
    return NetworkImage(cleanUrl);
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = normalizeUrl(url);

    if (cleanUrl.isEmpty) {
      return Image.asset(
        placeHolder ?? AssetConstants.placeHolder,
        width: width != 0.0 ? width : null,
        height: height != 0.0 ? height : null,
        fit: fit,
      );
    }

    return CachedNetworkImage(
      width:  width != 0.0 ?  width : null,
      height: height != 0.0 ?  height : null,
      fit: fit ?? BoxFit.scaleDown,
      imageUrl: cleanUrl,
      placeholder: (context, url) => Image.asset(placeHolder ?? AssetConstants.placeHolder),
      errorWidget: (context, url, error) => Image.asset(placeHolder ?? AssetConstants.placeHolder),
    );
  }
}

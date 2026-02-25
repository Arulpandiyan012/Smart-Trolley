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

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/assets_constants.dart';

class ImageView extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Widget? placeholder;
  final String? placeHolder;
  final int refreshVersion; // 🟢 NEW: Persistent version for cache-busting

  const ImageView({
    Key? key,
    required this.url,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.placeholder,
    this.placeHolder,
    this.refreshVersion = 0, // 🟢 Default
  }) : super(key: key);

  static String normalizeUrl(String? rawUrl, {int refreshVersion = 0}) {
    if (rawUrl == null || rawUrl.isEmpty) return "";
    String cleanUrl = rawUrl.trim();
    const String baseDomain = "https://ecom.thesmartedgetech.com"; // Define baseDomain here

    // 1. Allow local file paths (don't normalize them as URLs)
    if (cleanUrl.startsWith("/") || cleanUrl.contains(":\\") || cleanUrl.startsWith("file://")) {
      return cleanUrl;
    }

    // 🟢 1. RECOVERY: Check for 'placeholder' or 'no-image'
    if (cleanUrl.contains("placeholder") || cleanUrl.contains("no-image")) {
       return "";
    }

    // 🟢 2. FIX: Ensure absolute URL
    if (cleanUrl.startsWith("/")) {
      cleanUrl = "$baseDomain$cleanUrl";
    }

    // 🟢 3. PROTOCOL FIX (Force HTTPS)
    if (cleanUrl.startsWith("http://")) {
      cleanUrl = cleanUrl.replaceFirst("http://", "https://");
    }

    // 3. Transform broken storage paths to working cache paths (moved after absolute URL fix)
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

    // 🟢 4. CACHE BUSTING: Append version if refreshVersion > 0
    // We use a stable timestamp based on the version so that within one "refresh session",
    // the URL stays the same (allowing valid caching), but changes across sessions.
    if (refreshVersion > 0 && cleanUrl.isNotEmpty) {
       String connector = cleanUrl.contains("?") ? "&" : "?";
       // We use the version number itself to create a unique but stable 'v' param
       cleanUrl = "$cleanUrl${connector}rv=$refreshVersion";
    }
    return cleanUrl;
  }

  static ImageProvider getImageProvider(String? url, {String? fallbackAsset, int refreshVersion = 0}) {
    if (url == null || url.trim().isEmpty) {
      return AssetImage(fallbackAsset ?? AssetConstants.placeHolder);
    }
    
    final cleanUrl = url.trim();
    // Support local files
    if (cleanUrl.startsWith("/") || cleanUrl.contains(":\\") || cleanUrl.startsWith("file://")) {
      String path = cleanUrl.replaceFirst("file://", "");
      return FileImage(File(path));
    }

    final normalized = normalizeUrl(cleanUrl, refreshVersion: refreshVersion);
    if (normalized.isEmpty) {
      return AssetImage(fallbackAsset ?? AssetConstants.placeHolder);
    }
    return CachedNetworkImageProvider(normalized);
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return _placeholder();
    }

    final cleanUrl = url!.trim();

    // 🟢 Support Local Files Optimistically
    if (cleanUrl.startsWith("/") || cleanUrl.contains(":\\") || cleanUrl.startsWith("file://")) {
      String path = cleanUrl.replaceFirst("file://", "");
      return Image.file(
        File(path),
        width: width != 0.0 ? width : null,
        height: height != 0.0 ? height : null,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    final normalized = normalizeUrl(cleanUrl, refreshVersion: refreshVersion);
    if (normalized.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      width:  width != 0.0 ?  width : null,
      height: height != 0.0 ?  height : null,
      fit: fit ?? BoxFit.scaleDown,
      imageUrl: normalized,
      placeholder: (context, url) => _placeholder(),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  Widget _placeholder() {
    if (placeholder != null) return placeholder!;
    return Image.asset(
      placeHolder ?? AssetConstants.placeHolder,
      width: width != 0.0 ? width : null,
      height: height != 0.0 ? height : null,
      fit: fit,
    );
  }
}

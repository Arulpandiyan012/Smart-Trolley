/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/utils/server_configuration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bagisto_app_demo/screens/tracking/live_tracking_map_screen.dart';
import 'package:dio/dio.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';
import 'package:bagisto_app_demo/utils/app_navigation_key.dart';

class PushNotificationsManager {
  static PushNotificationsManager instance = PushNotificationsManager();

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  static const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void setUpFirebase(BuildContext context) {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      final String? payload = response.payload;
      if ((payload ?? "").isNotEmpty) {
        debugPrint("payload ---> $payload");
        Map<String, dynamic> payloadData = jsonDecode(payload ?? "");
        if (payloadData["type"] == "openFile") {
          openFile(payloadData["path"].toString());
        } else {
          _handleNotificationNavigation(payloadData, context);
        }
      }
    });
    _firebaseCloudMessagingListeners(context);
    checkInitialMessage(context);
  }

  Future<StyleInformation?> getNotificationStyle(String? image) async {
    if ((image ?? "").isNotEmpty) {
      final ByteData imageData = await NetworkAssetBundle(Uri.parse(image!)).load("");
      return BigPictureStyleInformation(
          ByteArrayAndroidBitmap(imageData.buffer.asUint8List()));
    } else {
      return null;
    }
  }

  void showNotification(String title, String body, String? payload, String? image) async {
    var notificationStyle = await getNotificationStyle(image);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel', 'Bagisto Notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        styleInformation: notificationStyle);

    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: payload);
  }

  static Future<String?> createFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("token---->$token");
      return token;
    } catch (e) {
      debugPrint("❌ Error fetching FCM Token: $e");
      return null;
    }
  }

  void subscribeToTopic() {
    _firebaseMessaging.subscribeToTopic("Bagisto_mobikul");
  }

  void _requestNotificationPermission() {
    _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    ).then((status) {
      debugPrint("🔔 Notification Permission Status: ${status.authorizationStatus}");
    });
  }

  static Future<void> syncToken(String token, {int? customerId, int? orderId, String? email}) async {
    if (token.isEmpty) return;

    int id = customerId ?? appStoragePref.getCustomerId();
    String customerEmail = email ?? appStoragePref.getCustomerEmail();

    if (id == 0 && customerEmail.isEmpty) return;

    debugPrint("🔄 Syncing FCM Token (Cust: $id, Email: $customerEmail, Order: $orderId)...");
    try {
      await Dio().post('https://ecom.thesmartedgetech.com/delivery-api.php', 
        data: {
          'action': 'update_customer_fcm',
          'customer_id': id,
          'email': customerEmail,
          'fcm_token': token,
          'order_id': orderId
        }
      );
      debugPrint("✅ FCM Token Synced Successfully.");
    } catch (e) {
      debugPrint("❌ FCM Sync Error: $e");
    }
  }

  void _firebaseCloudMessagingListeners(BuildContext context) async {
    _requestNotificationPermission();

    createFcmToken().then((token) async {
      if (token != null && token.isNotEmpty) {
        int customerId = appStoragePref.getCustomerId();
        String email = appStoragePref.getCustomerEmail();
        if (customerId != 0 || email.isNotEmpty) {
          syncToken(token, customerId: customerId, email: email);
        }
      }
    });

    subscribeToTopic();

    //When app is in Working state
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      debugPrint('on message ${message.data}');
      String title = notification?.title ?? "";
      String body = notification?.body ?? "";

      RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
      String parsedString = body.replaceAll(exp, ' ').trim();
      body = parsedString;

      String? imageUrl = message.data['attachment'];
      showNotification(title, body, json.encode(message.data), imageUrl);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("OnAppOpened: ${message.data}");
      _handleNotificationNavigation(message.data, context);
    });
  }

  void checkInitialMessage(BuildContext context) {
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message?.data != null) {
        debugPrint("Initial Message: ${message?.data}");
        _handleNotificationNavigation(message!.data, context);
      }
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data, BuildContext? context) {
    debugPrint("🔔 Handling Notification Navigation: $data");
    if (data['action'] == 'track_order' && data['order_id'] != null) {
      String orderId = data['order_id'].toString();
      debugPrint("🚀 Navigating to Live Tracking for Order $orderId");

      Future.delayed(const Duration(milliseconds: 800), () {
        if (navigatorKey.currentState != null) {
          debugPrint("✅ Using Global NavigatorKey for navigation");
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => LiveTrackingMapScreen(orderId: orderId),
            ),
          );
        } else if (context != null) {
          debugPrint("⚠️ NavigatorKey state is null, falling back to context navigation");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveTrackingMapScreen(orderId: orderId),
            ),
          );
        } else {
          debugPrint("❌ CRITICAL: No valid Navigator or Context found for navigation.");
        }
      });
    } else {
      debugPrint("ℹ️ Notification action '${data['action']}' not recognized or missing order_id.");
    }
  }

  void createDownloadNotification(int total, int progress, String name, String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 0), () async {
      var androidPlatformChannel = AndroidNotificationDetails(
          'progress channel', 'Bagisto Notification',
          channelShowBadge: false,
          importance: Importance.max,
          priority: Priority.high,
          onlyAlertOnce: true,
          showProgress: progress < total ? true : false,
          maxProgress: total,
          progress: progress);

      var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannel);
      await flutterLocalNotificationsPlugin.show(1, name, total == progress ? "Completed" : "Started",
          platformChannelSpecifics,
          payload: jsonEncode({"type": "openFile", "path": path}));
    });
  }

  Future<void> openFile(String fileName) async {
    const platform = MethodChannel(defaultChannelName);
    try {
      await platform.invokeMethod('fileviewer', fileName);
    } on PlatformException catch (e) {
      debugPrint("Failed ${e.toString()}");
    }
  }
}

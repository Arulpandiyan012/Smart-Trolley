/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'dart:io';
import 'package:bagisto_app_demo/screens/home_page/data_model/get_categories_drawer_data_model.dart';
import 'package:bagisto_app_demo/utils/firebase_auth_config.dart'; // 🟢 FOR SECONDARY APP
import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';
import 'package:bagisto_app_demo/utils/app_navigation.dart';
import 'package:bagisto_app_demo/utils/push_notifications_manager.dart';
import 'package:bagisto_app_demo/utils/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive/hive.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:bagisto_app_demo/screens/root/bottom_nav_scaffold.dart';
import 'data_model/product_model/product_screen_model.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';

// 🟢 IMPORTS FOR BLOC
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_repository.dart';
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_bloc.dart';
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_repository.dart';
import 'package:bagisto_app_demo/screens/drawer/bloc/drawer_bloc.dart';
import 'package:bagisto_app_demo/screens/drawer/bloc/drawer_repository.dart';
import 'package:bagisto_app_demo/widgets/internet_monitor.dart';

String? token;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message ${message.toMap()}');
}

AndroidNotificationChannel channel = const AndroidNotificationChannel(
  'high_importance_channel', 
  'High Importance Notifications', 
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🟢 Move to top
  await GetStorage.init(); // 🟢 FIX: Init Default Storage (Used by Onboarding)
  await GetStorage.init("configurationStorage");
  
  // 🟢 DIAGNOSTIC: Check session state
  appStoragePref.debugCheckStorage();
  HttpOverrides.global = MyHttpOverrides();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();
  
  // 🟢 Initialize Secondary App for ST-PRO Phone Auth Compatibility
  await Firebase.initializeApp(
    name: 'st_pro_auth',
    options: FirebaseAuthConfig.stProOptions,
  );
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await initHiveForFlutter();
  await hiveRegisterAdapter();
  runApp(
    RestartWidget(
      child: BagistoApp(GlobalData.locale),
    ),
  );
}

Future<void> hiveRegisterAdapter() async {
  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  ///Home Page Model
  Hive.registerAdapter(NewProductsModelAdapter());
  Hive.registerAdapter(NewProductsAdapter());
  Hive.registerAdapter(InventoriesAdapter());
  Hive.registerAdapter(InventorySourceAdapter());
  Hive.registerAdapter(ReviewsAdapter());
  Hive.registerAdapter(PriceHtmlAdapter());
  Hive.registerAdapter(ProductFlatsAdapter());
  Hive.registerAdapter(ImagesAdapter());
  Hive.registerAdapter(HomeCategoriesAdapter());
  Hive.registerAdapter(GetDrawerCategoriesDataAdapter());
}

class RestartWidget extends StatefulWidget {
  const RestartWidget({Key? key, required this.child}) : super(key: key);
  final Widget child;

  static restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<StatefulWidget> createState() {
    return _RestartWidgetState();
  }
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();
  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

class BagistoApp extends StatefulWidget {
  const BagistoApp(
    this.selectedLanguage, {
    Key? key,
  }) : super(key: key);

  final String? selectedLanguage;
  @override
  State<BagistoApp> createState() => _BagistoAppState();
}

class _BagistoAppState extends State<BagistoApp> {
  Locale? _locale;
  String appRoot = splash;

  @override
  void initState() {
    GlobalData.locale = appStoragePref.getCustomerLanguage();
    GlobalData.currencyCode = appStoragePref.getCurrencyCode();
    GlobalData.currencySymbol = appStoragePref.getCurrencySymbol();
    _locale = Locale(GlobalData.locale);
    PushNotificationsManager.instance.setUpFirebase(context);
    notification();
    super.initState();
  }

  Future<void> notification() async {
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, ThemeProvider themeNotifier, child) {
            
            // 🟢 MULTI BLOC PROVIDER WRAPPER
      // 🟢 OPTIMIZATION: Ensure CMS data is only fetched once per lifecycle
    // The previous code returned a SizedBox early, skipping the actual MaterialApp.
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomePageBloc>(
          create: (context) => HomePageBloc(HomePageRepositoryImp()),
        ),
        BlocProvider<DrawerBloc>(
          create: (context) => DrawerBloc(repository: DrawerPageRepositoryImp()),
        ),
                // Global Cart Provider
                BlocProvider<CartScreenBloc>(
                  create: (context) => CartScreenBloc(CartScreenRepositoryImp()),
                ),
              ],
              child: MaterialApp(
                theme: MobiKulTheme.lightTheme,
                darkTheme: MobiKulTheme.darkTheme,
                themeMode: themeNotifier.isDark == "true" ? ThemeMode.dark : ThemeMode.light,
                initialRoute: appRoot,
                onGenerateRoute: generateRoute,
                title: defaultAppTitle,
                debugShowCheckedModeBanner: false,
                supportedLocales: supportedLocale.map((e) => Locale(e)),
                localizationsDelegates: const [
                  ApplicationLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                localeResolutionCallback: (locale, supportedLocales) {
                  for (var supportedLocaleLanguage in supportedLocales) {
                    if (supportedLocaleLanguage.languageCode ==
                            locale?.languageCode &&
                        supportedLocaleLanguage.countryCode ==
                            locale?.countryCode) {
                      return supportedLocaleLanguage;
                    }
                  }
                  return supportedLocales.first;
                },
                locale: _locale,
                builder: (context, child) {
                  return InternetMonitor(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: child ?? const SizedBox(),
                    ),
                  );
                },
                       ),
            );
          },
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
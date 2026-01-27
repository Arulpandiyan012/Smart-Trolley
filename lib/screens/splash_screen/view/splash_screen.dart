/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */



import 'package:bagisto_app_demo/screens/splash_screen/utils/index.dart';

import '../../../utils/prefetching_helper.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    _navigateHomepage();
    preCacheCMSData();
    preCacheLanguageData();
    super.initState();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LottieBuilder.asset(
            AssetConstants.splashLottie,
            fit: BoxFit.contain, // Ensures the shrunk logo fits perfectly
          ),
        ),
      ),
    ),
  );
}
  _navigateHomepage() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    appDocPath = appDocDir.path;
    Timer(const Duration(seconds: defaultSplashDelay), () {
      Navigator.pushReplacementNamed(context, home);
    });
  }
}


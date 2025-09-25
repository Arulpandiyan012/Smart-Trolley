/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

// Application Specific Constants
const int defaultSplashDelay = 4;

const String baseDomain = "https://ecom.thesmartedgetech.com";

///base url for the application
const String baseUrl = "$baseDomain/graphql";
///default channel id
const String defaultChannelId = "1";

///default store code
const String defaultStoreCode = "en";

const String defaultLanguageName = "English";

const String defaultCurrencyCode = "INR";

const String defaultCurrencyName = "Indian Rupees";

const String defaultAppTitle = "Smart Trolley";

///default channel name
const String defaultChannelName = "com.webkul.bagisto_mobikul/channel";

const String demoEmail = "";

const String demoPassword = "";

///supported locales in app
List<String> supportedLocale = ['en', 'fr', 'nl', 'tr', 'es', 'ar', 'pt_br'];

const bool isPreFetchingEnable = true;

///supported payment methods in app
const availablePaymentMethods = [
  "cashondelivery",
  "moneytransfer",
];

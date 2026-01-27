/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/utils/server_configuration.dart';
import 'package:bagisto_app_demo/utils/shared_preference_keys.dart';
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:get_storage/get_storage.dart';

import '../data_model/account_models/account_info_details.dart';
import '../screens/home_page/data_model/get_categories_drawer_data_model.dart';

final appStoragePref = SharedPreferenceHelper();

class SharedPreferenceHelper {
  //named storage box for storing user app configuration data
  var configurationStorage = GetStorage("configurationStorage"); 

  String getDate() {
    return configurationStorage.read(date) ?? "";
  }

  void setDate(String setDate) {
    configurationStorage.write(date, setDate);
  }

  void setLanguageName(String customerLanguage) {
    configurationStorage.write(language, customerLanguage);
  }

  String getLanguageName() {
    return configurationStorage.read(language) ?? defaultLanguageName;
  }

  void setSortName(String selectedSort) {
    configurationStorage.write(sort, selectedSort);
  }

  String getSortName() {
    return configurationStorage.read(sort) ?? "";
  }

  void setCurrencyLabel(String currencyLabel) {
    configurationStorage.write(configCurrencyLabel, currencyLabel);
  }

  String getCurrencyLabel() {
    return configurationStorage.read(configCurrencyLabel) ?? defaultCurrencyName;
  }

  void onUserLogout() {
    configurationStorage.write(customerLoggedIn, false);
    configurationStorage.write(customerCartCount, 0);
    configurationStorage.write(customerName, StringConstants.welcomeGuest);
    configurationStorage.write(customerEmail, '');
    
    // 🟢 ADDED: Clear Phone on Logout
    configurationStorage.write("customerPhone", ''); 
    
    configurationStorage.write(customerProfilePicUrl, '');
    configurationStorage.write(customerBannerPicUrl, '');
    configurationStorage.write(customerToken, '0');
    configurationStorage.remove(customerDetails);
  }

  void setAddressData(bool isAddressData) {
    configurationStorage.write(addressData, isAddressData);
  }

  bool getAddressData() {
    return configurationStorage.read(addressData) ?? false;
  }

  void setCartCount(int cartCount) {
    configurationStorage.write(customerCartCount, cartCount);
  }

  int getCartCount() {
    return configurationStorage.read(customerCartCount) ?? 0;
  }

  void setCustomerId(int customerIdNew) {
    configurationStorage.write(customerId, customerIdNew);
  }

  int getCustomerId() {
    return configurationStorage.read(customerId) ?? 0;
  }

  void setCustomerToken(String customerTokenValue) {
    configurationStorage.write(customerToken, customerTokenValue);
  }

  String getCustomerToken() {
    return configurationStorage.read(customerToken) ?? "0";
  }

  void setCustomerEmail(String customerEmailNew) {
    configurationStorage.write(customerEmail, customerEmailNew);
  }

  String getCustomerEmail() {
    return configurationStorage.read(customerEmail) ?? "";
  }
  
  // 🟢 NEW: Set Customer Phone
  void setCustomerPhone(String phone) {
    configurationStorage.write("customerPhone", phone);
  }

  // 🟢 NEW: Get Customer Phone
  String getCustomerPhone() {
    return configurationStorage.read("customerPhone") ?? "";
  }

  void setCustomerImage(String customerImageValue) {
    configurationStorage.write(customerImage, customerImageValue);
  }

  String getCustomerImage() {
    return configurationStorage.read(customerImage) ?? "";
  }

  void setCustomerName(String customerNameValue) {
    configurationStorage.write(customerName, customerNameValue);
  }

  String getCustomerName() {
    return configurationStorage.read(customerName) ?? "";
  }

  bool getCustomerLoggedIn() {
    return configurationStorage.read(customerLoggedIn) ?? false;
  }

  void setCustomerLoggedIn(bool isLoggedIn) {
    configurationStorage.write(customerLoggedIn, isLoggedIn);
  }

  void setFingerPrintUser(String savedKey) {
    configurationStorage.write(fingerPrintUSer, savedKey);
  }

  String getFingerPrintUser() {
    return configurationStorage.read(fingerPrintUSer) ?? "";
  }

  void setFingerPrintPassword(String savedKey) {
    configurationStorage.write(fingerPrintPassword, savedKey);
  }

  String? getFingerPrintPassword() {
    return configurationStorage.read(fingerPrintPassword) ?? "";
  }

  void setTheme(String value) {
    configurationStorage.write(themeKey, value);
  }

  String getTheme() {
    return configurationStorage.read(themeKey) ?? "";
  }

  void setCurrencySymbol(String currencySymbol) {
    configurationStorage.write(configCurrencySymbol, currencySymbol);
  }

  String getCurrencySymbol() {
    return configurationStorage.read(configCurrencySymbol) ?? "\$";
  }

  void setCookieGet(String cookieData) {
    configurationStorage.write(cookie, cookieData);
  }

  String getCookieGet() {
    return configurationStorage.read(cookie) ?? "";
  }

  void setCustomerLanguage(String languageCode) {
    configurationStorage.write(customerLanguage, languageCode);
  }

  String getCustomerLanguage() {
    return configurationStorage.read(customerLanguage) ?? defaultStoreCode;
  }

  void setCurrencyCode(String currencyCode) {
    configurationStorage.write(configCurrencyCode, currencyCode);
  }

  String getCurrencyCode() {
    return configurationStorage.read(configCurrencyCode) ?? defaultCurrencyCode;
  }

  AccountInfoModel? getCustomerDetails() {
    return configurationStorage.read(customerDetails);
  }

  Future<void> setCustomerDetails(AccountInfoModel? details) {
    return configurationStorage.write(customerDetails, details);
  }

  Future<void> setDrawerCategories(GetDrawerCategoriesData? data) {
    return configurationStorage.write(drawerCatData, data);
  }

  GetDrawerCategoriesData? getDrawerCategories() {
    var data = configurationStorage.read(drawerCatData);
    if(data is GetDrawerCategoriesData){
      return data;
    }
    GetDrawerCategoriesData? drawerData =
        GetDrawerCategoriesData.fromJson(data ?? {});
    return drawerData;
  }

  void setCartId(String id) {
    configurationStorage.write("cartId", id);
  }

  String getCartId() {
    return configurationStorage.read("cartId") ?? "";
  }
}
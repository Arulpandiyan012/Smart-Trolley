/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/foundation.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';

abstract class CheckOutRepository {
  Future<AddressModel> callCheckoutAddressApi();
  Future<BaseModel?> saveAddress(Map<String, dynamic> addressData);
}

class CheckOutRepositoryImp implements CheckOutRepository {
  @override
  Future<AddressModel> callCheckoutAddressApi() async {
    AddressModel? addressModel;
    try {
      addressModel = await ApiClient().getAddressData();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return addressModel!;
  }

  String _mapStateToCode(String stateName) {
    String clean = stateName.trim().toUpperCase();
    Map<String, String> codes = {
      "TAMIL NADU": "TN", "TAMILNADU": "TN",
      "KERALA": "KL", "KARNATAKA": "KA",
      "ANDHRA PRADESH": "AP", "TELANGANA": "TG",
      "MAHARASHTRA": "MH", "DELHI": "DL",
      "NEW DELHI": "DL", "PUDUCHERRY": "PY",
      "WEST BENGAL": "WB", "UTTAR PRADESH": "UP",
      "MADHYA PRADESH": "MP", "GUJARAT": "GJ",
      "RAJASTHAN": "RJ", "PUNJAB": "PB",
      "HARYANA": "HR", "BIHAR": "BR",
      "ODISHA": "OR", "JHARKHAND": "JH",
      "CHHATTISGARH": "CT", "ASSAM": "AS",
    };
    return codes[clean] ?? stateName;
  }

  @override
  Future<BaseModel?> saveAddress(Map<String, dynamic> data) async {
    BaseModel? response;
    try {
      String company   = data['company_name'] ?? data['companyName'] ?? "";
      String fName     = data['first_name']   ?? data['firstName']   ?? "";
      String lName     = data['last_name']    ?? data['lastName']    ?? "User";
      String addr1     = data['address1']     ?? "";
      String addr2     = data['address2']     ?? "";
      String country   = data['country']      ?? "IN";
      String rawState  = data['state']        ?? "";
      String state     = _mapStateToCode(rawState); 
      String city      = data['city']         ?? "";
      String postcode  = data['postcode']     ?? data['postCode']    ?? "";
      String phone     = data['phone']        ?? "";
      String vat       = data['vat_id']       ?? "";
      String email     = data['email']        ?? "";
      bool isDefault   = data['default_address'] ?? true;

      debugPrint("🚀 SENDING: Name: $fName $lName, State: $state, Pin: $postcode");

      response = await ApiClient().createAddress(
        company, fName, lName, addr1, addr2, country, 
        state, city, postcode, phone, vat, isDefault, email
      );
      
      // 🟢 DEBUGGING: PRINT SERVER RESPONSE
      if (response != null) {
        debugPrint("✅ SERVER RESPONSE: Status: ${response.success}, Message: ${response.message}");
        if (response.success == false) {
          debugPrint("❌ SERVER ERROR DETAILS: ${response.message}");
        }
      } else {
        debugPrint("❌ SERVER RESPONSE IS NULL");
      }

    } catch (error, stacktrace) {
      debugPrint("❌ CRITICAL ERROR --> $error");
      debugPrint("❌ STACK --> $stacktrace");
    }
    return response;
  }
}
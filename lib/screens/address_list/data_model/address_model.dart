/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:json_annotation/json_annotation.dart';
import '../../../data_model/graphql_base_model.dart';
import 'country_model.dart';

part 'address_model.g.dart';

@JsonSerializable()
class AddressModel extends BaseModel {
  @JsonKey(name: "data")
  List<AddressData>? addressData = [];
  CountriesData? countryData;
  AddressModel({this.addressData});

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AddressModelToJson(this);
}

@JsonSerializable()
class AddressData {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? companyName;
  String? vatId;
  String? address1; 
  String? country;
  String? countryName;
  String? stateName;
  String? state;
  String? city;
  String? postcode;
  String? phone;
  bool? isDefault;
  String? createdAt;
  String? updatedAt;
  String? addressType;
  int? billingAddressId;
  int? shippingAddressId;

  AddressData({
    this.id,
    this.firstName,
    this.lastName,
    this.companyName,
    this.vatId,
    this.address1,
    this.country,
    this.countryName,
    this.stateName,
    this.state,
    this.city,
    this.postcode,
    this.phone,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
    this.addressType,
    this.shippingAddressId,
    this.billingAddressId,
    this.email
  });

  // 🟢 MANUAL PARSER: This fixes the "List vs String" crash
  factory AddressData.fromJson(Map<String, dynamic> json) {
    
    // Helper to extract String from either String or List
    String? getString(String key) {
      var val = json[key];
      if (val == null) return null;
      if (val is List) return val.join(", "); // <--- THE FIX
      return val.toString();
    }

    return AddressData(
      id: getString('id'),
      firstName: getString('first_name') ?? getString('firstName'),
      lastName: getString('last_name') ?? getString('lastName'),
      email: getString('email'),
      companyName: getString('company_name'),
      vatId: getString('vat_id'),
      
      // Check both 'address1' (Server) and 'address' (App)
      address1: getString('address1') ?? getString('address'),
      
      country: getString('country'),
      countryName: getString('country_name'),
      stateName: getString('state_name'),
      state: getString('state'),
      city: getString('city'),
      postcode: getString('postcode'),
      phone: getString('phone'),
      
      // Handle different boolean keys
      isDefault: json['default_address'] == true || json['is_default'] == true,
      
      addressType: getString('address_type'),
      updatedAt: getString('updated_at'),
      createdAt: getString('created_at'),
    );
  }

  Map<String, dynamic> toJson() => _$AddressDataToJson(this);
}
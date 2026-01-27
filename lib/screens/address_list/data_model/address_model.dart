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
  List<AddressData>? addressData;
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
  @JsonKey(name: "first_name") // Automatically maps snake_case to camelCase
  String? firstName;
  @JsonKey(name: "last_name")
  String? lastName;
  String? email;
  @JsonKey(name: "company_name")
  String? companyName;
  @JsonKey(name: "vat_id")
  String? vatId;
  
  // Use a custom converter for the Address field if it's sometimes a List
  @JsonKey(name: "address1", fromJson: _addressFromJson) 
  String? address1; 
  
  @JsonKey(name: "country_name")
  String? countryName;
  String? country;
  @JsonKey(name: "state_name")
  String? stateName;
  String? state;
  String? city;
  String? postcode;
  String? phone;
  
  @JsonKey(name: "is_default")
  bool? isDefault;
  
  @JsonKey(name: "created_at")
  String? createdAt;
  @JsonKey(name: "updated_at")
  String? updatedAt;
  @JsonKey(name: "address_type")
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

  // 1. Connect back to generated code to remove the "unreferenced" warning
  factory AddressData.fromJson(Map<String, dynamic> json) => _$AddressDataFromJson(json);

  Map<String, dynamic> toJson() => _$AddressDataToJson(this);

  // 2. 🟢 THE SAFETY FIX: Handles the "List vs String" logic during generation
  static String? _addressFromJson(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.join(", ");
    return value.toString();
  }
}
/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'package:json_annotation/json_annotation.dart';

part 'account_info_details.g.dart';

@JsonSerializable()
class AccountInfoModel {
  String? id;
  String? email;
  String? firstName;
  String? lastName;
  String? name;
  String? imageUrl;
  String? dateOfBirth;
  String? phone;
  String? gender; // 🟢 Added
  bool? subscribedToNewsLetter;

  AccountInfoModel(
      {this.id,
      this.email,
      this.firstName,
      this.lastName,
      this.name,
      this.imageUrl,
      this.dateOfBirth,
      this.phone,
      this.gender, // 🟢 Added
      this.subscribedToNewsLetter});

  factory AccountInfoModel.fromJson(Map<String, dynamic> json) {
    return AccountInfoModel(
      id: (json['id'] ?? json['customer_id'] ?? json['customerId'])?.toString(),
      email: (json['email'] ?? json['customer_email'] ?? json['customerEmail'])?.toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? json['first_name'])?.toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? json['last_name'])?.toString(),
      name: (json['name'] ?? json['full_name'] ?? json['customer_name'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['profile_image_url'])?.toString(),
      dateOfBirth: (json['dateOfBirth'] ?? json['date_of_birth'] ?? json['dob'] ?? json['customer_dob'])?.toString(),
      phone: (json['phone'] ?? json['customer_phone'] ?? json['telephone'])?.toString(),
      gender: (json['gender'] ?? json['customer_gender'])?.toString(),
      subscribedToNewsLetter: (json['subscribedToNewsLetter'] ?? json['is_subscribed'] ?? json['subscribed_to_newsletter']) == true || (json['is_subscribed'] == 1),
    );
  }

  Map<String, dynamic> toJson() => _$AccountInfoModelToJson(this);
}

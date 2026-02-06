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

import '../graphql_base_model.dart';

part 'account_update_model.g.dart';

@JsonSerializable()
class AccountUpdate extends BaseModel{
  @JsonKey(name: "customer")
  Data? data;

  AccountUpdate({this.data});

  factory AccountUpdate.fromJson(Map<String, dynamic> json) =>
      _$AccountUpdateFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$AccountUpdateToJson(this);
}
@JsonSerializable()
class Data {
  String? id;
  String? email;
  String? firstName;
  String? lastName;
  String? name;
  String? gender;
  String? dateOfBirth;
  String? phone;
  String? imageUrl;
  bool? status;
  Group? group;
  bool? subscribedToNewsLetter;

  Data(
      {this.id,
        this.email,
        this.firstName,
        this.lastName,
        this.name,
        this.gender,
        this.dateOfBirth,
        this.phone,
        this.status,
        this.group,
        this.imageUrl,
        this.subscribedToNewsLetter
     });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: (json['id'] ?? json['customer_id'] ?? json['customerId'])?.toString(),
      email: (json['email'] ?? json['customer_email'] ?? json['customerEmail'])?.toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? json['first_name'])?.toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? json['last_name'])?.toString(),
      name: (json['name'] ?? json['full_name'] ?? json['customer_name'])?.toString(),
      gender: (json['gender'] ?? json['customer_gender'])?.toString(),
      dateOfBirth: (json['dateOfBirth'] ?? json['date_of_birth'] ?? json['dob'] ?? json['customer_dob'])?.toString(),
      phone: (json['phone'] ?? json['customer_phone'] ?? json['telephone'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['profile_image_url'])?.toString(),
      status: json['status'],
      subscribedToNewsLetter: (json['subscribedToNewsLetter'] ?? json['is_subscribed'] ?? json['subscribed_to_newsletter']) == true || (json['is_subscribed'] == 1),
    );
  }

  Map<String, dynamic> toJson() =>
      _$DataToJson(this);

}
@JsonSerializable()
class Group {
  int? id;
  String? name;
Group({this.id,this.name});
  factory Group.fromJson(Map<String, dynamic> json) =>
      _$GroupFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GroupToJson(this);
}
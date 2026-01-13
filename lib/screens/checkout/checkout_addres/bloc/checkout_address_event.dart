/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:equatable/equatable.dart';

abstract class CheckOutBaseEvent extends Equatable{}

class CheckOutAddressEvent extends CheckOutBaseEvent{
  @override
  List<Object> get props => [];
}

class AddAddressEvent extends CheckOutBaseEvent {
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? country;
  final String? postCode;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? email; // <--- ADDED EMAIL

  AddAddressEvent({
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.country,
    this.postCode,
    this.phone,
    this.firstName,
    this.lastName,
    this.email, // <--- ADDED EMAIL
  });

  @override
  List<Object> get props => [
    address1 ?? "", address2 ?? "", city ?? "", 
    phone ?? "", firstName ?? "", lastName ?? "", email ?? ""
  ];
}
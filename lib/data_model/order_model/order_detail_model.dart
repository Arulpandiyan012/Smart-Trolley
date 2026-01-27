/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/data_model/graphql_base_error_model.dart';
import '../../screens/cart_screen/cart_model/cart_data_model.dart';

// 🛑 NO GENERATED CODE IMPORTS

class OrderDetail extends GraphQlBaseErrorModel {
  FormattedPrice? formattedPrice;
  int? id;
  String? incrementId;
  String? status;
  String? shippingTitle;
  String? createdAt;
  BillingAddress? billingAddress;
  BillingAddress? shippingAddress;
  List<Items>? items;
  Payment? payment;

  OrderDetail({
      this.id,
      this.incrementId,
      this.shippingTitle,
      this.status,
      this.createdAt,
      this.billingAddress,
      this.shippingAddress,
      this.items,
      this.payment,
      this.formattedPrice
  });

  // 🛠️ MANUAL PARSER
  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      data = json['data'];
    }

    var order = OrderDetail();
    
    order.id = _toInt(data['id']);
    order.incrementId = data['incrementId']?.toString();
    order.status = data['status']?.toString();
    order.createdAt = data['createdAt']?.toString();
    order.shippingTitle = data['shippingTitle']?.toString();
    
    // Parse Address
    if (data['billingAddress'] != null) {
      order.billingAddress = BillingAddress.fromJson(Map<String, dynamic>.from(data['billingAddress']));
    }
    if (data['shippingAddress'] != null) {
      order.shippingAddress = BillingAddress.fromJson(Map<String, dynamic>.from(data['shippingAddress']));
    }

    // Parse Items
    if (data['items'] != null && data['items'] is List) {
      order.items = (data['items'] as List)
          .map((i) => Items.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    // Parse Payment
    if (data['payment'] != null) {
      order.payment = Payment.fromJson(Map<String, dynamic>.from(data['payment']));
    }
    
    // Parse Price
    if (data['formattedPrice'] != null) {
       order.formattedPrice = FormattedPrice.fromJson(Map<String, dynamic>.from(data['formattedPrice']));
    }

    // Success Status
    if (json.containsKey('success')) {
      order.responseStatus = json['success'];
    }

    return order;
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }
}

class Payment {
  String? id;
  String? method;
  String? methodTitle;

  Payment({this.id, this.method, this.methodTitle});

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString(),
      method: json['method']?.toString(),
      methodTitle: json['methodTitle']?.toString() ?? json['method_title']?.toString(),
    );
  }
}

class BillingAddress {
  String? id;
  String? firstName;
  String? lastName;
  String? companyName;
  String? address1; 
  String? postcode;
  String? city;
  String? state;
  String? country;
  String? email;
  String? phone;

  BillingAddress({
    this.id, this.firstName, this.lastName, this.companyName, 
    this.address1, this.postcode, this.city, this.state, 
    this.country, this.email, this.phone,
  });

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      id: json['id']?.toString(),
      firstName: json['firstName']?.toString() ?? json['first_name']?.toString(),
      lastName: json['lastName']?.toString() ?? json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address1: json['address1']?.toString() ?? json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      postcode: json['postcode']?.toString(),
    );
  }
}

class Items {
  String? id;
  String? sku;
  String? type;
  String? name;
  int? qtyOrdered;
  int? qtyShipped;
  int? qtyInvoiced;
  int? qtyCanceled;
  int? qtyRefunded;
  String? productId;
  OrderProduct? product;
  FormattedPrice? formattedPrice;
  dynamic additional;

  Items({
    this.id, this.sku, this.type, this.name, 
    this.qtyOrdered, this.qtyShipped, this.qtyInvoiced, 
    this.qtyCanceled, this.qtyRefunded, this.productId, 
    this.product, this.formattedPrice, this.additional
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    var item = Items(
      id: json['id']?.toString(),
      sku: json['sku']?.toString(),
      name: json['name']?.toString(),
      qtyOrdered: OrderDetail._toInt(json['qtyOrdered'] ?? json['qty_ordered']),
      qtyShipped: OrderDetail._toInt(json['qtyShipped'] ?? 0),
      qtyInvoiced: OrderDetail._toInt(json['qtyInvoiced'] ?? 0),
      qtyCanceled: OrderDetail._toInt(json['qtyCanceled'] ?? 0),
      qtyRefunded: OrderDetail._toInt(json['qtyRefunded'] ?? 0),
      productId: json['productId']?.toString() ?? json['product_id']?.toString(),
    );
    
    if (json['formattedPrice'] != null) {
       item.formattedPrice = FormattedPrice.fromJson(Map<String, dynamic>.from(json['formattedPrice']));
    }
    
    if (json['product'] != null) {
       item.product = OrderProduct.fromJson(Map<String, dynamic>.from(json['product']));
    }
    
    return item;
  }
}

class OrderProduct {
  String? id;
  String? sku;
  String? name;
  List<Images>? images;

  OrderProduct({this.id, this.sku, this.name, this.images});

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
     var op = OrderProduct(
       id: json['id']?.toString(),
       sku: json['sku']?.toString(),
       name: json['name']?.toString(),
     );
     
     if (json['images'] != null && json['images'] is List) {
       op.images = (json['images'] as List)
           .map((i) => Images.fromJson(Map<String, dynamic>.from(i)))
           .toList();
     }
     return op;
  }

  // 👇 ADD THIS METHOD
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'images': images?.map((i) => i.toJson()).toList(),
    };
  }
}

class Images {
  String? url;
  String? path;

  Images({this.url, this.path});

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      url: json['url']?.toString(),
      path: json['path']?.toString(),
    );
  }

  // 👇 ADD THIS METHOD
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'path': path,
    };
  }
}

class SuperAttributes {
  int? attributeId;
  int? optionId;
  SuperAttributes({this.attributeId, this.optionId});
  factory SuperAttributes.fromJson(Map<String, dynamic> json) => SuperAttributes();
}

class Options {
  String? id;
  String? label;
  Options({this.id, this.label});
  factory Options.fromJson(Map<String, dynamic> json) => Options();
}
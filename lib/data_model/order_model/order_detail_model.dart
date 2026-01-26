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

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static String? _safeLink(dynamic val) {
     if (val == null) return null;
     if (val is String) {
        if (val.isEmpty || val.startsWith("{") || val.startsWith("[")) return null;
        return val;
     }
     if (val is Map) {
        return val['url']?.toString() ?? val['imageUrl']?.toString() ?? val['path']?.toString() ?? val['image_url']?.toString();
     }
     return null;
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
  String? image; // 🟢 NEW: Direct image link if available
  dynamic additional;
  String? couponCode;
  double? weight;
  double? totalWeight;
  Map<String, dynamic>? rawData; // 🟢 FIX: Store raw JSON for brute-force recovery

  Items({
    this.id, this.sku, this.type, this.name, 
    this.qtyOrdered, this.qtyShipped, this.qtyInvoiced, 
    this.qtyCanceled, this.qtyRefunded, this.productId, 
    this.product, this.formattedPrice, this.additional,
    this.image,
    this.couponCode,
    this.weight,
    this.totalWeight,
    this.rawData
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    var item = Items(
      id: json['id']?.toString(),
      sku: json['sku']?.toString(),
      type: json['type']?.toString(),
      name: json['name']?.toString(),
      couponCode: json['couponCode']?.toString(),
      weight: OrderDetail._toDouble(json['weight']),
      totalWeight: OrderDetail._toDouble(json['totalWeight']),
      qtyOrdered: OrderDetail._toInt(json['qtyOrdered'] ?? json['qty_ordered'] ?? 0),
      qtyShipped: OrderDetail._toInt(json['qtyShipped'] ?? 0),
      qtyInvoiced: OrderDetail._toInt(json['qtyInvoiced'] ?? 0),
      qtyCanceled: OrderDetail._toInt(json['qtyCanceled'] ?? 0),
      qtyRefunded: OrderDetail._toInt(json['qtyRefunded'] ?? 0),
      productId: json['productId']?.toString() ?? json['product_id']?.toString(),
      image: OrderDetail._safeLink(json['image_url']) ?? OrderDetail._safeLink(json['image']) ?? OrderDetail._safeLink(json['product_image']) ?? OrderDetail._safeLink(json['imageUrl']) ?? OrderDetail._safeLink(json['url']) ?? OrderDetail._safeLink(json['base_image']) ?? OrderDetail._safeLink(json['base_image_url']) ?? OrderDetail._safeLink(json['thumbnail']) ?? OrderDetail._safeLink(json['thumbnail_url']), 
      rawData: json, // 🟢 Populate raw JSON
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
  BaseImage? baseImage; 
  String? image; 
  Map<String, dynamic>? rawData; // 🟢 FIX: Store raw JSON for brute-force recovery

  OrderProduct({this.id, this.sku, this.name, this.images, this.baseImage, this.image, this.rawData});

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
     var op = OrderProduct(
       id: json['id']?.toString(),
       sku: json['sku']?.toString(),
       name: json['name']?.toString(),
       image: OrderDetail._safeLink(json['image_url']) ?? OrderDetail._safeLink(json['image']) ?? OrderDetail._safeLink(json['base_image_url']) ?? OrderDetail._safeLink(json['imageUrl']) ?? OrderDetail._safeLink(json['url']) ?? OrderDetail._safeLink(json['base_image']) ?? OrderDetail._safeLink(json['thumbnail']) ?? OrderDetail._safeLink(json['thumbnail_url']) ?? OrderDetail._safeLink(json['product_image']), 
       rawData: json, // 🟢 Populate raw JSON
     );
     
     if (json['images'] != null && json['images'] is List) {
       op.images = (json['images'] as List)
           .map((i) => Images.fromJson(Map<String, dynamic>.from(i)))
           .toList();
     }

     if (json['base_image'] != null) {
        op.baseImage = BaseImage.fromJson(Map<String, dynamic>.from(json['base_image']));
     } else if (json['baseImage'] != null) {
        op.baseImage = BaseImage.fromJson(Map<String, dynamic>.from(json['baseImage']));
     } else if (json['cacheGalleryImages'] != null) {
        op.baseImage = BaseImage.fromJson(Map<String, dynamic>.from(json['cacheGalleryImages']));
     } else if (json['cache_gallery_images'] != null) {
        op.baseImage = BaseImage.fromJson(Map<String, dynamic>.from(json['cache_gallery_images']));
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
      url: json['url']?.toString() ?? json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? json['image']?.toString() ?? json['path']?.toString(),
      path: json['path']?.toString() ?? json['image']?.toString(),
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

class BaseImage {
  String? smallImageUrl;
  String? mediumImageUrl;
  String? largeImageUrl;
  String? originalImageUrl;

  BaseImage({this.smallImageUrl, this.mediumImageUrl, this.largeImageUrl, this.originalImageUrl});

  factory BaseImage.fromJson(Map<String, dynamic> json) {
     return BaseImage(
       smallImageUrl: json['small_image_url']?.toString() ?? json['smallImageUrl']?.toString(),
       mediumImageUrl: json['medium_image_url']?.toString() ?? json['mediumImageUrl']?.toString(),
       largeImageUrl: json['large_image_url']?.toString() ?? json['largeImageUrl']?.toString(),
       originalImageUrl: json['original_image_url']?.toString() ?? json['originalImageUrl']?.toString(),
     );
  }
}

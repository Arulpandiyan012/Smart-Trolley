/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:json_annotation/json_annotation.dart';

part 'currency_language_model.g.dart';

@JsonSerializable()
class CurrencyLanguageList {
  List<Locales>? locales;
  List<Currencies>? currencies;
  Currencies? baseCurrency;
  String? id;
  String? name;
  int? rootCategoryId;

  CurrencyLanguageList({
    this.locales,
    this.name,
    this.id,
    this.currencies,
    this.baseCurrency,
    this.rootCategoryId,
  });

  factory CurrencyLanguageList.fromJson(Map<String, dynamic> json) =>
      _$CurrencyLanguageListFromJson(json);

  // FIX: Removed @override because this class doesn't extend a parent with toJson()
  Map<String, dynamic> toJson() => _$CurrencyLanguageListToJson(this);
}

@JsonSerializable()
class Locales {
  String? id;
  String? name;
  String? code;

  Locales({
    this.id,
    this.name,
    this.code,
  });

  factory Locales.fromJson(Map<String, dynamic> json) =>
      _$LocalesFromJson(json);

  Map<String, dynamic> toJson() => _$LocalesToJson(this);
}

@JsonSerializable()
class Currencies {
  String? id;
  String? name;
  String? code;
  String? symbol;
  
  Currencies({
    this.id,
    this.name,
    this.code,
    this.symbol, // Added this to match your field definition
  });

  factory Currencies.fromJson(Map<String, dynamic> json) =>
      _$CurrenciesFromJson(json);

  Map<String, dynamic> toJson() => _$CurrenciesToJson(this);
}
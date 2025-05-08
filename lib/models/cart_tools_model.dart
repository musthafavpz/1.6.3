// To parse this JSON data, do
//
//     final cartTools = cartToolsFromJson(jsonString);

import 'dart:convert';

CartTools cartToolsFromJson(String str) => CartTools.fromJson(json.decode(str));

String cartToolsToJson(CartTools data) => json.encode(data.toJson());

class CartTools {
    String courseSellingTax;
    String currencyPosition;
    String currencySymbol;
    String tax;
    String currency_position;
    String currency_symbol;

    CartTools({
        required this.courseSellingTax,
        required this.currencyPosition,
        required this.currencySymbol,
        this.tax = "0",
        required this.currency_position,
        required this.currency_symbol,
    });

    factory CartTools.fromJson(Map<String, dynamic> json) => CartTools(
        courseSellingTax: json["course_selling_tax"] ?? "0",
        currencyPosition: json["currency_position"] ?? "left",
        currencySymbol: json["currency_symbol"] ?? "\$",
        tax: json["tax"] ?? json["course_selling_tax"] ?? "0",
        currency_position: json["currency_position"] ?? "left",
        currency_symbol: json["currency_symbol"] ?? "\$",
    );

    Map<String, dynamic> toJson() => {
        "course_selling_tax": courseSellingTax,
        "currency_position": currencyPosition,
        "currency_symbol": currencySymbol,
        "tax": tax,
        "currency_position": currency_position,
        "currency_symbol": currency_symbol,
    };
}

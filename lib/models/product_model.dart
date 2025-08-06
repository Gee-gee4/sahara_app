import 'package:sahara_app/models/product_variation_model.dart';

class ProductModel {
  final int productId;
  final String productName;
  final List<ProductVariationModel> productVariations;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.productVariations,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'],
      productName: json['productName'],
       productVariations: (json['productVariations'] as List)
          .map((e) => ProductVariationModel.fromJson(
              Map<String, dynamic>.from(e))) // 👈 Safe cast
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productVariations': productVariations.map((v) => v.toJson()).toList(),
      };
}

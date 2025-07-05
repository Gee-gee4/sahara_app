import 'package:sahara_app/models/product_model.dart';

class ProductCategoryModel {
  final int productCategoryId;
  final String productCategoryName;
  final List<ProductModel> products;

  ProductCategoryModel({
    required this.productCategoryId,
    required this.productCategoryName,
    required this.products,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      productCategoryId: json['productCategoryId'],
      productCategoryName: json['productCategoryName'],
      products: (json['products'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productCategoryId': productCategoryId,
        'productCategoryName': productCategoryName,
        'products': products.map((p) => p.toJson()).toList(),
      };
}

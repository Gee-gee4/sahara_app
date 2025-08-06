class ProductCardDetailsModel {
  final int productVariationId;
  final String productVariationName;
  final int productCategoryId;
  final String productCategoryName;
  final double productPrice;
  final double productDiscount;

  ProductCardDetailsModel({
    required this.productVariationId,
    required this.productVariationName,
    required this.productCategoryId,
    required this.productCategoryName,
    required this.productPrice,
    required this.productDiscount,
  });

  factory ProductCardDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProductCardDetailsModel(
      productVariationId: json['productVariationId'],
      productVariationName: json['productVariationName'],
      productCategoryId: json['productCategoryId'],
      productCategoryName: json['productCategoryName'],
      productPrice: (json['productPrice'] ?? 0).toDouble(),
      productDiscount: (json['productDiscount'] ?? 0).toDouble(),
    );
  }
}

class ProductVariationModel {
  final int productVariationId;
  final String productVariationName;
  final double productVariationPrice;
  final String? productVariationImageUrl;

  ProductVariationModel({
    required this.productVariationId,
    required this.productVariationName,
    required this.productVariationPrice,
    this.productVariationImageUrl,
  });

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    return ProductVariationModel(
      productVariationId: json['productVariationId'],
      productVariationName: json['productVariationName'],
      productVariationPrice: (json['productVariationPrice'] as num).toDouble(),
      productVariationImageUrl: json['productVariationImageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'productVariationId': productVariationId,
        'productVariationName': productVariationName,
        'productVariationPrice': productVariationPrice,
        'productVariationImageUrl': productVariationImageUrl,
      };
}

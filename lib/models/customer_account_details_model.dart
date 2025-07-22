import 'package:sahara_app/models/product_card_details_model.dart';

class CustomerAccountDetailsModel {
  final String customerName;
  final String? mask;
  final String agreementTypeName;
  final String description;
  final String accountCreditTypeName;
  final double customerAccountBalance;
  final bool customerIsActive;
  final List<ProductCardDetailsModel> products;
  final String startTime;
  final String endTime;
  final int frequecy;
  final String? frequencyPeriod;
  final String dateToFuel;

  CustomerAccountDetailsModel({
    required this.customerName,
    this.mask,
    required this.agreementTypeName,
    required this.description,
    required this.accountCreditTypeName,
    required this.customerAccountBalance,
    required this.customerIsActive,
    required this.products,
    required this.startTime,
    required this.endTime,
    required this.frequecy,
    this.frequencyPeriod,
   required this.dateToFuel
  });

  factory CustomerAccountDetailsModel.fromJson(Map<String, dynamic> json) {
    return CustomerAccountDetailsModel(
      customerName: json['customer']['customerName'],
      mask: (json['identifiers'] as List).isNotEmpty ? json['identifiers'][0]['mask'] : null,
      agreementTypeName: json['agreementTypeName'],
      description: json['description'],
      accountCreditTypeName: json['accountCreditTypeName'],
      customerAccountBalance: (json['customerAccountBalance'] ?? 0).toDouble(),
      customerIsActive: json['customerAccountIsActive'],
      products: (json['products'] as List).map((e) => ProductCardDetailsModel.fromJson(e)).toList(),
      startTime: json['accountPolicies']['startTime'] ?? '',
      endTime: json['accountPolicies']['endTime'] ?? '',
      frequecy: json['accountPolicies']['frequecy'] ?? 0,
      frequencyPeriod: json['accountPolicies']['frequencyPeriod'],
      dateToFuel: json['accountPolicies']['daysToFuel'] ?? ''
    );
  }
}

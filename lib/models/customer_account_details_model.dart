import 'package:sahara_app/models/product_card_details_model.dart';

class CustomerAccountDetailsModel {
  final String customerName;
  final String? mask;
  final String? cardMask;
  final List<String>? equipmentMask;


  final String agreementTypeName;
  final String agreementDescription;
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
    this.cardMask,
    this.equipmentMask,
    required this.agreementTypeName,
    required this.agreementDescription,
    required this.description,
    required this.accountCreditTypeName,
    required this.customerAccountBalance,
    required this.customerIsActive,
    required this.products,
    required this.startTime,
    required this.endTime,
    required this.frequecy,
    this.frequencyPeriod,
    required this.dateToFuel,
  });

  factory CustomerAccountDetailsModel.fromJson(Map<String, dynamic> json) {
  final identifiers = json['identifiers'] as List<dynamic>;
  String? cardMask;
  List<String> equipmentMask = [];

  for (var item in identifiers) {
    final type = item['tagTypeName'];
    final mask = item['mask'];
    if (type == 'Card') {
      cardMask = mask;
    } else if (type == 'EquipmentRegNumber') {
      equipmentMask.add(mask);
    }
  }

  return CustomerAccountDetailsModel(
    customerName: json['customer']['customerName'],
    mask: identifiers.isNotEmpty ? identifiers[0]['mask'] : null,
    cardMask: cardMask,
    equipmentMask: equipmentMask,
    agreementTypeName: json['agreementTypeName'],
    agreementDescription: json['agreementDescription'],
    description: json['description'],
    accountCreditTypeName: json['accountCreditTypeName'],
    customerAccountBalance: (json['customerAccountBalance'] ?? 0).toDouble(),
    customerIsActive: json['customerAccountIsActive'],
    products: (json['products'] as List).map((e) => ProductCardDetailsModel.fromJson(e)).toList(),
    startTime: json['accountPolicies']['startTime'] ?? '',
    endTime: json['accountPolicies']['endTime'] ?? '',
    frequecy: json['accountPolicies']['frequecy'] ?? 0,
    frequencyPeriod: json['accountPolicies']['frequencyPeriod'],
    dateToFuel: json['accountPolicies']['daysToFuel'] ?? '',
  );
}

}

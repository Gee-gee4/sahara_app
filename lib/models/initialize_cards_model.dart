class InitializeCardsModel {
  InitializeCardsModel({
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.accountCreditTypeName,
    required this.customerAccountMask,
    required this.customerAccountNumber,
    required this.accountCreditType,
  });
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String accountCreditTypeName;
  final String customerAccountMask;
  final int customerAccountNumber;
  final int accountCreditType;

  factory InitializeCardsModel.fromJson(Map<String, dynamic> json) {
    return InitializeCardsModel(
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      accountCreditTypeName: json['accountCreditTypeName'] ?? '',
      customerAccountMask: json['customerAccountMask'] ?? '',
      customerAccountNumber: json['customerAccountNumber'] ?? 0,
      accountCreditType: json['accountCreditType'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAccountNumber': customerAccountNumber,
      'accountCreditType': accountCreditType,
      'accountCreditTypeName': accountCreditTypeName,
      'customerAccountMask': customerAccountMask,
    };
  }
}

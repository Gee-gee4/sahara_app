class PaymentModeModel {
  PaymentModeModel({
    required this.payModeId,
    required this.payModeName,
    required this.payModeCategory,
    required this.payModeDisplayName,
    required this.isPosAccepted,
  });
  final int payModeId;
  final String payModeName;
  final String payModeCategory;
  final String payModeDisplayName;
  final bool isPosAccepted;

  factory PaymentModeModel.fromJson(Map<String, dynamic> json) {
    return PaymentModeModel(
      payModeId: json['payModeId'],
      payModeName: json['payModeName'] ?? '',
      payModeCategory: json['payModeCategory'] ?? '',
      payModeDisplayName: json['payModeDisplayName'] ?? '',
      isPosAccepted: json['isPosAccepted'],
    );
  }

  Map<String, dynamic> toJson() => {
    'payModeId' : payModeId,
    'payModeName' : payModeName,
    'payModeCategory' : payModeCategory,
    'payModeDisplayName' : payModeDisplayName,
    'isPosAccepted' : isPosAccepted
  };
}

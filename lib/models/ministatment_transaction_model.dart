// lib/models/transaction_model.dart
class MinistatmentTransactionModel {
  final String transactionType;
  final int transactionCount;
  final double transactionTotal;
  final String transactionDateCreated;
  final String channelName;
  final String? transactionDesc;

  MinistatmentTransactionModel({
    required this.transactionType,
    required this.transactionCount,
    required this.transactionTotal,
    required this.transactionDateCreated,
    required this.channelName,
    this.transactionDesc,
  });

  factory MinistatmentTransactionModel.fromJson(Map<String, dynamic> json) {
    return MinistatmentTransactionModel(
      transactionType: json['transactionType'] ?? '',
      transactionCount: json['transactionCount'] ?? 0,
      transactionTotal: (json['transactionTotal'] ?? 0).toDouble(),
      transactionDateCreated: json['transactionDateCreated'] ?? '',
      channelName: json['channelName'] ?? '',
      transactionDesc: json['transactionDesc'],
    );
  }
}
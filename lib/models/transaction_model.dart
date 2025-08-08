class TransactionModel {
  final String nozzle;
  final String productName;
  final String dateTimeSold;
  final double price;
  final double volume;
  final double totalAmount;
  final String? transactionId;
  final String? productId;

  TransactionModel({
    required this.nozzle,
    required this.productName,
    required this.dateTimeSold,
    required this.price,
    required this.volume,
    required this.totalAmount,
    this.productId,
    this.transactionId,
  });
}

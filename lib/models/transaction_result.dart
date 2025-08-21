class TransactionResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? error;

  TransactionResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory TransactionResult.success(String message, {dynamic data}) {
    return TransactionResult(success: true, message: message, data: data);
  }

  factory TransactionResult.error(String error) {
    return TransactionResult(success: false, message: error, error: error);
  }
}
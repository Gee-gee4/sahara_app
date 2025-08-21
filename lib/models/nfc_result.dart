class NFCResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? error;

  NFCResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory NFCResult.success(String message, {dynamic data}) {
    return NFCResult(success: true, message: message, data: data);
  }

  factory NFCResult.error(String error) {
    return NFCResult(success: false, message: error, error: error);
  }
}
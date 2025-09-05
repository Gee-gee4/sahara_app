class ResponseModel<T> {
  ResponseModel({required this.isSuccessfull, required this.message, required this.body});
  final bool isSuccessfull;
  final String message;
  final T body;
}
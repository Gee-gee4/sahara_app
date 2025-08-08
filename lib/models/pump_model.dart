class PumpModel {
  final String pumpName;
  final String pumpId;

  PumpModel({required this.pumpName, required this.pumpId});

  @override
  String toString() {
    return 'PumpModel(pumpName: $pumpName, pumpId: $pumpId)';
  }
}
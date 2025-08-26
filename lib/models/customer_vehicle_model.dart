class CustomerVehicleModel {
  final String regNo;
  final String fuelType; // not in JSON, so default to N/A
  final String tankCapacity; // not in JSON, so default to N/A
  final String startTime;
  final String endTime;
  final String fuelDays;

  CustomerVehicleModel({
    required this.regNo,
    required this.fuelType,
    required this.tankCapacity,
    required this.startTime,
    required this.endTime,
    required this.fuelDays,
  });

  factory CustomerVehicleModel.fromJson(Map<String, dynamic> json) {
    return CustomerVehicleModel(
      regNo: json['regNo'] ?? 'N/A',
      fuelType: 'N/A', // not provided in API
      tankCapacity: 'N/A', // not provided in API
      startTime: json['startTime'] ?? 'N/A',
      endTime: json['endTime'] ?? 'N/A',
      fuelDays: json['daysToFuel'] ?? 'N/A',
    );
  }
}

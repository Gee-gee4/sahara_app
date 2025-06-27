//DEVICE ID: UP1A.231005.007
class DummyValidator {
  static const allowedIds = [
    'UP1A.231005.007', // Replace with real ID
  ];

  static Future<bool> isDeviceAllowed(String deviceId) async {
    await Future.delayed(Duration(seconds: 1)); // simulate network
    return allowedIds.contains(deviceId);
  }
}

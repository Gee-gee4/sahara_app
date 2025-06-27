import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceId() async {
  final info = await DeviceInfoPlugin().androidInfo;
  return info.id; // Most reliable unique ID
}

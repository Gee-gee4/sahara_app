import 'package:flutter_udid/flutter_udid.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';

Future<String> getSavedOrFetchDeviceId() async {
  final savedDeviceId = await SharedPrefsHelper.getDeviceId();
  if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
    return savedDeviceId;
  } else {
    final newDeviceId = await FlutterUdid.udid;
    await SharedPrefsHelper.saveDeviceId(newDeviceId);
    return newDeviceId;
  }
}
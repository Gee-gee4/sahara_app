// lib/helpers/ref_generator.dart
import 'package:shared_preferences/shared_preferences.dart';

class RefGenerator {
  /// Generates: TR(channelId)(YYMMDD)(HHMMSS)
  static Future<String> generate({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final channelId = prefs.getInt('channelId') ?? 0;

    final dt = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');

    final yy = (dt.year % 100).toString().padLeft(2, '0'); // 2-digit year
    final mm = two(dt.month);
    final dd = two(dt.day);
    final hh = two(dt.hour);
    final mi = two(dt.minute);
    final ss = two(dt.second);

    return 'TR$channelId$yy$mm$dd$hh$mi$ss';
  }
}

// ignore_for_file: avoid_print

class UIDConverter {
  /// Converts UID from app format (big-endian hex) to POS format (little-endian decimal)
  static String convertToPOSFormat(String appUID) {
    try {
      // Remove any spaces and convert to uppercase
      String cleaned = appUID.replaceAll(' ', '').toUpperCase();

      // Ensure even length by padding with 0 if needed
      if (cleaned.length % 2 != 0) {
        cleaned = '0$cleaned';
      }

      // Split into byte pairs and reverse the order
      List<String> bytes = [];
      for (int i = 0; i < cleaned.length; i += 2) {
        bytes.add(cleaned.substring(i, i + 2));
      }

      // Reverse byte order (big-endian to little-endian)
      String reversedHex = bytes.reversed.join('');

      // Convert to decimal
      int decimal = int.parse(reversedHex, radix: 16);

      return decimal.toString();
    } catch (e) {
      print('Error converting UID: $e');
      return appUID; // Return original if conversion fails
    }
  }

  /// For debugging - shows both formats
  static void debugUID(String appUID) {
    String posFormat = convertToPOSFormat(appUID);
    print('🔍 UID Conversion:');
    print('   App format (hex): $appUID');
    print('   POS format (decimal): $posFormat');
  }
}
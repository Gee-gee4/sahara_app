// lib/helpers/printing/unified_printer_helper.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class UnifiedPrinterHelper {
  // Main printing method that handles all print types
  static Future<void> printDocument({
    required BuildContext context,
    required StaffListModel user,
    required String documentType,
    required Future<PrintResult> Function() printFunction,
    int? customDelayMs,
    bool navigateToHome = true,
    String? successMessage,
    bool ignoreReceiptCount = false,
  }) async {
    // Check printer status before starting
    final printerReady = await _checkPrinterStatus(context);
    if (!printerReady) return;

    // Use receiptCount only if ignoreReceiptCount is false
    final receiptCount = ignoreReceiptCount ? 1 : await SharedPrefsHelper.getReceiptCount();

    for (int i = 0; i < receiptCount; i++) {
      print('🖨️ Printing $documentType ${i + 1} of $receiptCount');

      if (i > 0) {
        final statusOk = await _checkPrinterStatus(context);
        if (!statusOk) return;
      }

      final result = await printFunction();

      if (result != PrintResult.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${documentType.capitalize()} ${i + 1} failed to print: ${_getPrintResultMessage(result)}"),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      print('✅ $documentType ${i + 1} print command sent');

      if (i < receiptCount - 1) {
        final delayMs = customDelayMs ?? _getDefaultDelayForDocumentType(documentType);
        await Future.delayed(Duration(milliseconds: delayMs));
        await _waitForPrinterToFinish();
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? 'All ${documentType.toLowerCase()}s printed successfully!'),
          backgroundColor: _getSuccessColor(),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(seconds: 2));

      if (navigateToHome) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
          (route) => false,
        );
      }
    }
  }

  // Get appropriate delay based on document type
  static int _getDefaultDelayForDocumentType(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'carddetails':
        return 3000;
      case 'ministatement':
        return 2500;
      case 'reprint':
      case 'reversal':
      case 'topup':
      default:
        return 2000;
    }
  }

  // Get success color
  static Color _getSuccessColor() {
    try {
      return hexToColor('8f9c68');
    } catch (e) {
      return Colors.green;
    }
  }

  // Printer status checking (shared across all helpers)
  static Future<bool> _checkPrinterStatus(BuildContext context) async {
    try {
      final TelpoFlutterChannel _printer = TelpoFlutterChannel();
      final TelpoStatus status = await _printer.checkStatus();

      print('🖨️ Printer status: ${status.toString()}');

      switch (status) {
        case TelpoStatus.ok:
          print('✅ Printer ready');
          return true;

        case TelpoStatus.noPaper:
          await _showPrinterErrorDialog(
            context,
            'No Paper Found',
            'Please load paper into the printer and try again.',
            Icons.assignment,
          );
          return false;

        case TelpoStatus.overHeat:
          await _showPrinterErrorDialog(
            context,
            'Printer Overheated',
            'The printer is too hot. Please wait for it to cool down before printing.',
            Icons.warning_amber,
          );
          return false;

        case TelpoStatus.cacheIsFull:
          await _showPrinterErrorDialog(
            context,
            'Printer Buffer Full',
            'The printer buffer is full. Please wait a moment and try again.',
            Icons.memory,
          );
          return false;

        case TelpoStatus.unknown:
          await _showPrinterErrorDialog(
            context,
            'Printer Error',
            'Failed! Please check if the device supports printing services and try again.',
            Icons.error_outline,
          );
          return false;
      }
    } catch (e) {
      print('❌ Error checking printer status: $e');
      await _showPrinterErrorDialog(
        context,
        'Printer Check Failed',
        'Unable to check printer status: ${e.toString()}',
        Icons.help_outline,
      );
      return false;
    }
  }

  // Simplified printer error dialog - OK button only
  static Future<void> _showPrinterErrorDialog(
    BuildContext context, 
    String title, 
    String message, 
    IconData icon
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorsUniversal.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: ColorsUniversal.buttonsColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: ColorsUniversal.buttonsColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 16, color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  // Shared print result message
  static String _getPrintResultMessage(PrintResult result) {
    switch (result) {
      case PrintResult.success:
        return 'Print successful';
      case PrintResult.noPaper:
        return 'No paper in printer';
      case PrintResult.lowBattery:
        return 'Printer battery low';
      case PrintResult.overHeat:
        return 'Printer overheated';
      case PrintResult.dataCanNotBeTransmitted:
        return 'Data transmission failed';
      case PrintResult.other:
        return 'Other printer error';
    }
  }

  // Shared printer wait function
  static Future<void> _waitForPrinterToFinish() async {
    final printer = TelpoFlutterChannel();
    int maxWaitTime = 30;
    int waitCount = 0;

    while (waitCount < maxWaitTime) {
      try {
        final status = await printer.checkStatus();
        print('📊 Printer status: $status');

        if (status == TelpoStatus.ok) {
          print('✅ Printer finished, ready for next document');
          await Future.delayed(Duration(milliseconds: 500));
          return;
        }

        if (status == TelpoStatus.noPaper || status == TelpoStatus.overHeat) {
          print('❌ Printer error: $status');
          return;
        }
      } catch (e) {
        print('❌ Error checking printer status: $e');
      }

      await Future.delayed(Duration(seconds: 1));
      waitCount++;
    }

    print('⚠️ Max wait time reached, proceeding anyway');
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
// lib/helpers/printer/topup_printer_service.dart
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class TopUpPrinterService {
  static final _instance = TopUpPrinterService._internal();
  factory TopUpPrinterService() => _instance;
  TopUpPrinterService._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printTopUpReceipt({
    required String title, // "Top Up" or "Reverse Top Up"
    required String refNumber,
    required String termNumber,
    required double amount,
    required Map<String, dynamic> topUpData,
    required String accountNo,
    required String staffName,
    required bool isReversal,
    String? companyName,
    String? channelName,
  }) async {
    final sheet = TelpoPrintSheet();
    
    // Extract customer data
    final customerAccount = topUpData['customerAccount'] ?? {};
    final customer = customerAccount['customer'] ?? {};
    final customerName = customer['customerName'] ?? 'N/A';
    final accountBalance = customerAccount['accountBalance']?.toString() ?? 'N/A';
    final accountMask = customerAccount['accountMask'] ?? 'N/A';
    final agreementTypeName = customerAccount['agreementTypeName'] ?? 'N/A';

    // Header
    sheet.addElement(
      PrintData.text(
        companyName ?? 'SAHARA FCS', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(
      PrintData.text(
        channelName ?? 'Station', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 4));
    
    // Transaction type
    sheet.addElement(
      PrintData.text(
        title, 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    
    // Transaction details
    sheet.addElement(PrintData.text('TERM# $termNumber', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.text('REF# $refNumber', fontSize: PrintedFontSize.size24));
    
    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Amount section
    if (isReversal) {
      sheet.addElement(
        PrintData.text(
          'Reversed Amount  -Ksh ${amount.toStringAsFixed(2)}', 
          fontSize: PrintedFontSize.size24
        ),
      );
    } else {
      sheet.addElement(
        PrintData.text(
          'Top Up           Ksh ${amount.toStringAsFixed(2)}', 
          fontSize: PrintedFontSize.size24
        ),
      );
    }
    
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text(
        'Card Balance     Ksh $accountBalance', 
        fontSize: PrintedFontSize.size24
      ),
    );

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Customer information
    sheet.addElement(PrintData.text('Customer: $customerName', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Account: $accountNo', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Card: $accountMask', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Account Type: $agreementTypeName', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Date and staff
    sheet.addElement(
      PrintData.text(
        'Date: ${DateTime.now().toString().substring(0, 19)}', 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Served By: $staffName', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 4));

    // Footer
    sheet.addElement(
      PrintData.text(
        "Cardholder's signature", 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 4));
    sheet.addElement(
      PrintData.text(
        'THANK YOU', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(
      PrintData.text(
        'CUSTOMER COPY', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(
      PrintData.text(
        'Powered by Sahara FCS', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 20));

    return await _printer.print(sheet);
  }
}
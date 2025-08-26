// lib/helpers/printer/ministatement_printer_service.dart
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/ministatment_transaction_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class MiniStatementPrinterService {
  static final _instance = MiniStatementPrinterService._internal();
  factory MiniStatementPrinterService() => _instance;
  MiniStatementPrinterService._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printMiniStatement({
    required StaffListModel user,
    required CustomerAccountDetailsModel accountDetails,
    required List<MinistatmentTransactionModel> transactions,
    required String refNumber,
    required String termNumber,
    String? companyName,
    String? channelName,
  }) async {
    final sheet = TelpoPrintSheet();

    // Header
    sheet.addElement(
      PrintData.text(companyName ?? 'SAHARA FCS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(
      PrintData.text(channelName ?? 'CMB Station', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 4));

    // Statement type
    sheet.addElement(
      PrintData.text('MINI STATEMENT', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));

    // Transaction details
    sheet.addElement(PrintData.text('TERM# $termNumber', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.text('REF# $refNumber', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Recent transactions
    sheet.addElement(PrintData.text('RECENT TRANSACTIONS', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));

    if (transactions.isEmpty) {
      sheet.addElement(
        PrintData.text('No transactions found', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
      );
    } else {
      // Transaction header
      sheet.addElement(PrintData.text('Type      Amount    Date', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));

      // Transaction lines
      for (var transaction in transactions.take(10)) {
        // Limit to 10 most recent
        final type = transaction.transactionType.padRight(8).substring(0, 8);
        final amount =
            '${transaction.transactionTotal >= 0 ? '+' : ''}${transaction.transactionTotal.toStringAsFixed(0)}'.padLeft(
              8,
            );
        final date = _formatDateForPrint(transaction.transactionDateCreated);

        sheet.addElement(PrintData.text('$type  $amount  $date', fontSize: PrintedFontSize.size24));
        sheet.addElement(PrintData.space(line: 2));

        // Add channel name as sub-line
        // final channelName = transaction.channelName.padRight(20).substring(0, 20);
        // sheet.addElement(PrintData.text('  $channelName', fontSize: PrintedFontSize.size24));
      }
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // // Current balance summary
    // sheet.addElement(
    //   PrintData.text(
    //     'CURRENT BALANCE: Ksh ${accountDetails.customerAccountBalance.toStringAsFixed(2)}',
    //     alignment: PrintAlignment.center,
    //     fontSize: PrintedFontSize.size24,
    //   ),
    // );

    // sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Customer information
    sheet.addElement(PrintData.text('ACCOUNT INFORMATION', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Customer:  ${accountDetails.customerName}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Card:  ${accountDetails.cardMask ?? 'N/A'}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text(
        'Balance:  Ksh ${accountDetails.customerAccountBalance.toStringAsFixed(2)}',
        fontSize: PrintedFontSize.size24,
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text('Account Type:  ${accountDetails.accountCreditTypeName}', fontSize: PrintedFontSize.size24),
    );

    if (accountDetails.products.isNotEmpty) {
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
      sheet.addElement(PrintData.text('Discount Voucher: Available', fontSize: PrintedFontSize.size24));
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Statement date and staff
    sheet.addElement(
      PrintData.text('Date:  ${DateTime.now().toString().substring(0, 19)}', fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Served  By:  ${user.staffName}', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 4));

    // Approval section
    sheet.addElement(PrintData.text('APPROVAL', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    sheet.addElement(
      PrintData.text(
        'Please confirm the accuracy of the',
        alignment: PrintAlignment.center,
        fontSize: PrintedFontSize.size24,
      ),
    );
    sheet.addElement(
      PrintData.text(
        'statement and report any discrepancies',
        alignment: PrintAlignment.center,
        fontSize: PrintedFontSize.size24,
      ),
    );
    sheet.addElement(PrintData.text('immediately', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text('Cardholder Signature', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 4));

    // Footer
    sheet.addElement(PrintData.text('THANK YOU', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    sheet.addElement(
      PrintData.text('CUSTOMER COPY', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(
      PrintData.text('Powered by Sahara FCS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 20));

    return await _printer.print(sheet);
  }

  String _formatDateForPrint(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
    } catch (e) {
      return dateString.substring(0, 10); // Fallback to first 10 characters
    }
  }
}

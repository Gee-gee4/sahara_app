// lib/helpers/printer/reverse_sale_printer_service.dart
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class ReverseSalePrinterService {
  static final _instance = ReverseSalePrinterService._internal();
  factory ReverseSalePrinterService() => _instance;
  ReverseSalePrinterService._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printReversalReceipt({
    required StaffListModel user,
    required Map<String, dynamic> apiData,
    required String originalRefNumber,
    required String reversalRefNumber,
    required String terminalName,
    String? companyName,
    String? channelName,
  }) async {
    final sheet = TelpoPrintSheet();
    
    // Extract data from API response
    final ticket = apiData['ticket'] ?? {};
    final customerAccount = apiData['customerAccount'] ?? {};
    final customer = customerAccount['customer'];
    final paymentList = ticket['paymentList'] as List? ?? [];
    final ticketLines = ticket['ticketLines'] as List? ?? [];
    
    // Determine if this was a card sale
    final bool wasCardSale = customer != null && customerAccount['customerAccountNumber'] != 0;
    
    // Get payment info
    final payment = paymentList.isNotEmpty ? paymentList[0] : {};
    final paymentModeName = payment['paymentModeName'] ?? 'Cash';
    // ignore: unused_local_variable
    final totalPaid = (payment['totalPaid'] ?? 0).toDouble();
    final totalUsed = (payment['totalUsed'] ?? 0).toDouble();
    
    // Get customer info (for card sales)
    String customerName = '';
    String cardMask = '';
    String accountType = '';
    String vehicleNumber = '';
    double customerBalance = 0;
    
    if (wasCardSale) {
      customerName = customer['customerName'] ?? '';
      // Get card mask from identifiers
      final identifiers = customerAccount['identifiers'] as List? ?? [];
      for (var identifier in identifiers) {
        if (identifier['tagTypeName'] == 'Card') {
          cardMask = identifier['mask'] ?? '';
          break;
        }
      }
      accountType = customerAccount['agreementDescription'] ?? '';
      customerBalance = (customerAccount['customerAccountBalance'] ?? 0).toDouble();
      
      // Get vehicle numbers
      final vehicles = customerAccount['customerVehicles'] as List? ?? [];
      if (vehicles.isNotEmpty) {
        final vehicleRegs = vehicles.map((v) => v['regNo']).where((reg) => reg != null).toList();
        vehicleNumber = vehicleRegs.isNotEmpty ? vehicleRegs.join(', ') : 'No Equipment';
      } else {
        vehicleNumber = 'No Equipment';
      }
    }

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
        channelName ?? (ticket['channelName'] ?? 'Station'), 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 4));
    
    // Transaction type
    sheet.addElement(
      PrintData.text(
        'REVERSE SALE', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    
    // Transaction details
    sheet.addElement(PrintData.text('TERM# $terminalName', fontSize: PrintedFontSize.size24));
    // sheet.addElement(PrintData.text('ORIGINAL REF# $originalRefNumber', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.text('REF# $reversalRefNumber', fontSize: PrintedFontSize.size24));
    
    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Reversal notice
    sheet.addElement(
      PrintData.text(
        '*** TRANSACTION REVERSED ***', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));

    // Product listing header
    sheet.addElement(PrintData.text('Prod    Price  Qty  Total', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));

    // Product lines (negative values for reversal)
    for (var line in ticketLines) {
      final name = (line['productVariationName'] ?? '').toString().padRight(7).substring(0, 7);
      final price = (line['productVariationPrice'] ?? 0).toStringAsFixed(0).padLeft(5);
      final qty = -(line['units'] ?? 0); // Negative quantity
      final total = (-(line['totalMoneySold'] ?? 0)).toStringAsFixed(0).padLeft(5); // Negative total
      sheet.addElement(PrintData.text('$name  $price  $qty  $total', fontSize: PrintedFontSize.size24));
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Totals section (negative values for reversal)
    sheet.addElement(PrintData.text('Sub Total    -${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Total        -${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Net Total    -${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Payment/Refund section
    if (wasCardSale) {
      sheet.addElement(PrintData.text('Card Refund  -${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('New Balance  ${(customerBalance + totalUsed).toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    } else {
      sheet.addElement(PrintData.text('$paymentModeName Refund  -${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Customer info (only for card sales)
    if (wasCardSale) {
      sheet.addElement(PrintData.text('Customer: $customerName', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Card No: $cardMask', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Account Type: $accountType', fontSize: PrintedFontSize.size24));
      if (vehicleNumber != 'No Equipment') {
        sheet.addElement(PrintData.space(line: 2));
        sheet.addElement(PrintData.text('Vehicle: $vehicleNumber', fontSize: PrintedFontSize.size24));
      }
      sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    }

    // Date information
    // sheet.addElement(
    //   PrintData.text(
    //     'Original Date: ${ticket['ticketCreationDate'] ?? 'N/A'}', 
    //     fontSize: PrintedFontSize.size24
    //   ),
    // );
    
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text(
        'Date: ${DateTime.now().toString().substring(0, 19)}', 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Served By: ${user.staffName}', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 4));

    // Refund notice
    sheet.addElement(
      PrintData.text(
        'REFUND PROCESSED', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));

    if (wasCardSale) {
      sheet.addElement(
        PrintData.text(
          'Amount has been credited', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'back to your account', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
    } else {
      sheet.addElement(
        PrintData.text(
          'Please collect your refund', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'from the cashier', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
    }

    sheet.addElement(PrintData.space(line: 4));

    // Approval section (only for card sales)
    if (wasCardSale) {
      sheet.addElement(
        PrintData.text(
          'REVERSAL ACKNOWLEDGMENT', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'Customer acknowledges the reversal', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'of transaction and refund', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'as shown above.', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(
        PrintData.text(
          'Customer Signature', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(PrintData.space(line: 4));
    }

    // Footer
    sheet.addElement(
      PrintData.text(
        'REVERSAL COMPLETE', 
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
// lib/helpers/printer/reprint_printer_service.dart
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class ReprintPrinterService {
  static final _instance = ReprintPrinterService._internal();
  factory ReprintPrinterService() => _instance;
  ReprintPrinterService._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printReprintReceipt({
    required StaffListModel user,
    required Map<String, dynamic> apiData,
    required String refNumber,
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
    // ignore: unused_local_variable
    final paymentModeName = payment['paymentModeName'] ?? 'Cash';
    final totalPaid = (payment['totalPaid'] ?? 0).toDouble();
    final totalUsed = (payment['totalUsed'] ?? 0).toDouble();
    final change = totalPaid - totalUsed;
    
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
    
    // Transaction type with reprint notice
    sheet.addElement(
      PrintData.text(
        'SALE REPRINT', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    
    // Transaction details
    sheet.addElement(PrintData.text('TERM# $terminalName', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.text('REF# $refNumber', fontSize: PrintedFontSize.size24));
    
    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Product listing header
    sheet.addElement(PrintData.text('Prod    Price  Qty  Total', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));

    // Product lines from API data
    for (var line in ticketLines) {
      final name = (line['productVariationName'] ?? '').toString().padRight(7).substring(0, 7);
      final price = (line['productVariationPrice'] ?? 0).toStringAsFixed(0).padLeft(5);
      final qty = line['units'] ?? 0;
      final total = (line['totalMoneySold'] ?? 0).toStringAsFixed(0).padLeft(5);
      sheet.addElement(PrintData.text('$name  $price  $qty  $total', fontSize: PrintedFontSize.size24));
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Totals section
    sheet.addElement(PrintData.text('Sub Total    ${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Total        ${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Net Total    ${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Payment section
    if (wasCardSale) {
      sheet.addElement(PrintData.text('Card         ${totalUsed.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Balance      ${customerBalance.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    } else {
      sheet.addElement(PrintData.text('Cash         ${totalPaid.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Change       ${change.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
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
    sheet.addElement(
      PrintData.text(
        'Date: ${ticket['ticketCreationDate'] ?? 'N/A'}', 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text(
        'Served By: ${ticket['staffName'] ?? 'N/A'}', 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text(
        'Reprinted By: ${user.staffName}', 
        fontSize: PrintedFontSize.size24
      ),
    );

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 4));

    // Approval section (only for card sales)
    if (wasCardSale) {
      sheet.addElement(
        PrintData.text(
          'APPROVAL', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'Cardholder acknowledges receipt', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'of goods/services in the amount', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(
        PrintData.text(
          'shown above.', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(
        PrintData.text(
          'Cardholder Signature', 
          alignment: PrintAlignment.center, 
          fontSize: PrintedFontSize.size24
        ),
      );
      sheet.addElement(PrintData.space(line: 4));
    }

    // Footer with reprint notice
    sheet.addElement(
      PrintData.text(
        'THANK YOU', 
        alignment: PrintAlignment.center, 
        fontSize: PrintedFontSize.size24
      ),
    );
    sheet.addElement(
      PrintData.text(
        'CUSTOMER COPY - REPRINT', 
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
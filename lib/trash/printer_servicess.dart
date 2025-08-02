import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class PrinterService {
  static final _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printReceipt({
    required String title,
    required String station,
    required List<String> items,
    required String cash,
    required String change,
    required String date,
    required String cashier,
  }) async {
    final sheet = TelpoPrintSheet();

    // Header
    sheet.addElement(PrintData.text(title, 
      alignment: PrintAlignment.center, 
      fontSize: PrintedFontSize.size34
    ));
    
    sheet.addElement(PrintData.text(station, 
      alignment: PrintAlignment.center, 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.space(line: 4));
    sheet.addElement(PrintData.text('SALE', 
      alignment: PrintAlignment.center, 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('TERM# 8458cn34e3kf343', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('REF# TR45739547549219', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('---------------------------------------------------', 
      fontSize: PrintedFontSize.size24
    ));

    // Items
    sheet.addElement(PrintData.text('Prod    Price  Qty  Total', 
      fontSize: PrintedFontSize.size24
    ));
    
    for (final item in items) {
      sheet.addElement(PrintData.text(item, 
        fontSize: PrintedFontSize.size24
      ));
    }
    
    sheet.addElement(PrintData.text('---------------------------------------------------', 
      fontSize: PrintedFontSize.size24
    ));
    
    // Totals
    sheet.addElement(PrintData.text('Cash     $cash', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('Change   $change', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('---------------------------------------------------', 
      fontSize: PrintedFontSize.size24
    ));
    
    // Footer
    sheet.addElement(PrintData.text('Date: $date', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('Served By: $cashier', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('---------------------------------------------------', 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('THANK YOU', 
      alignment: PrintAlignment.center, 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('CUSTOMER COPY', 
      alignment: PrintAlignment.center, 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.text('Powered by Sahara FCS', 
      alignment: PrintAlignment.center, 
      fontSize: PrintedFontSize.size24
    ));
    
    sheet.addElement(PrintData.space(line: 20));

    return await _printer.print(sheet);
  }
}
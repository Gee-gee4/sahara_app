import 'package:flutter/material.dart';
import 'package:sahara_app/trash/printer_servicess.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class HomeTelpo extends StatefulWidget {
  const HomeTelpo({super.key});

  @override
  State<HomeTelpo> createState() => _HomeTelpoState();
}

class _HomeTelpoState extends State<HomeTelpo> {
  final PrinterService _printer = PrinterService();
  bool _isPrinting = false;

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      final result = await _printer.printReceipt(
        title: 'SAHARA FCS',
        station: 'Station',
        items: ['Petrol    200  1  200', 'Diesel    100  3  300'],
        cash: '1000',
        change: '500',
        date: DateTime.now().toString().substring(0, 19),
        cashier: 'Gee',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == PrintResult.success ? 'Receipt printed successfully!' : 'Print failed: ${result.name}',
          ),
          backgroundColor: result == PrintResult.success ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = TextStyle(fontFamily: 'Courier', fontSize: 16);
    final TextStyle balanceStyle = TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Receipt', style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: Colors.orange[600],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text('SAHARA FCS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Center(child: Text('Station')),
                const SizedBox(height: 8),
                const Center(
                  child: Text('SALE', style: TextStyle(decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 8),
                Text('TERM# 8458cn34e3kf343', style: receiptStyle),
                Text('REF# TR45739547549219', style: receiptStyle),
                Divider(),
                Text('Prod    Price  Qty  Total', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Divider(),
                Text('Petrol    200  1  200', style: receiptStyle),
                Text('Diesel    100  3  300', style: receiptStyle),
                Divider(),
                _row('Cash', '1000', balanceStyle),
                _row('Change', '500', receiptStyle),
                Divider(),
                _row('Date', DateTime.now().toString().substring(0, 19), receiptStyle),
                _row('Served By', 'Gee', receiptStyle),
                Divider(),
                const Center(
                  child: Text('THANK YOU', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Center(child: Text('CUSTOMER COPY')),
                const SizedBox(height: 4),
                const Center(child: Text('Powered by Sahara FCS', style: TextStyle(fontSize: 11))),
              ],
            ),
          ),
        ),
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: _isPrinting ? null : _printReceipt,
        backgroundColor: Colors.blueGrey,
        child: _isPrinting 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.print, color: Colors.white),
      ),
    );
  }

  Widget _row(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Expanded(
            child: Text(value, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

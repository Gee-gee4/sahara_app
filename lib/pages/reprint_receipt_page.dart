// lib/pages/reprint_receipt_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/reprint_printer_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class ReprintReceiptPage extends StatefulWidget {
  final StaffListModel user;
  final Map<String, dynamic> apiData;
  final String refNumber;
  final String terminalName;
  final String? companyName;
  final String? channelName;

  const ReprintReceiptPage({
    super.key,
    required this.user,
    required this.apiData,
    required this.refNumber,
    required this.terminalName,
    this.companyName,
    this.channelName,
  });

  @override
  State<ReprintReceiptPage> createState() => _ReprintReceiptPageState();
}

class _ReprintReceiptPageState extends State<ReprintReceiptPage> {
  
  Future<void> _printReceipt() async {
    await ReprintPrinterHelper.printReprintReceipt(
      context: context,
      user: widget.user,
      apiData: widget.apiData,
      refNumber: widget.refNumber,
      terminalName: widget.terminalName,
      companyName: widget.companyName,
      channelName: widget.channelName,
    );
  }

  void _showEndTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Exit Page'),
        content: const Text(
          'You will lose all progress if you exit from this page',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = const TextStyle(fontFamily: 'Courier', fontSize: 14);
    final TextStyle balanceStyle = const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.red);
    
    // Extract data from API response
    final ticket = widget.apiData['ticket'] ?? {};
    final customerAccount = widget.apiData['customerAccount'] ?? {};
    final customer = customerAccount['customer'];
    final paymentList = ticket['paymentList'] as List? ?? [];
    final ticketLines = ticket['ticketLines'] as List? ?? [];
    
    // Determine if this was a card sale
    final bool wasCardSale = customer != null && customerAccount['customerAccountNumber'] != 0;
    
    // Get payment info
    final payment = paymentList.isNotEmpty ? paymentList[0] : {};
    final paymentModeName = payment['paymentModeName'] ?? '';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          _showEndTransactionDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Reprint', style: TextStyle(color: Colors.white70)),
          centerTitle: true,
          backgroundColor: ColorsUniversal.appBarColor,
          leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
          ),
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
                  // Header
                  Center(
                    child: Text(
                      widget.companyName ?? 'SAHARA FCS', 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                  Center(child: Text(widget.channelName ?? (ticket['channelName'] ?? 'Station'))),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('SALE REPRINT', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 8),
                  
                  // Transaction info
                  Text('TERM# ${widget.terminalName}', style: receiptStyle),
                  Text('REF# ${widget.refNumber}', style: receiptStyle),
                  const Divider(),

                  // Product listing header
                  Text('Prod    Price  Qty   Total', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),

                  // Product lines  directly from API data
                  ...ticketLines.map((line) {
                    final name = (line['productVariationName'] ?? '').toString().padRight(7).substring(0, 7);
                    final price = (line['productVariationPrice'] ?? 0).toStringAsFixed(0).padLeft(4);
                    final qty = (line['units'] ?? 0).toStringAsFixed(2);
                    final total = (line['totalMoneySold'] ?? 0).toStringAsFixed(0).padLeft(5);
                    return Text('$name  $price  $qty  $total', style: receiptStyle);
                  }),

                  const Divider(),

                  // Totals section
                  _row('Sub Total', totalUsed.toStringAsFixed(2), receiptStyle),
                  _row('Total', totalUsed.toStringAsFixed(2), receiptStyle),
                  _row('Net Total', totalUsed.toStringAsFixed(2), receiptStyle),
                  const Divider(),

                  // Payment section
                  if (wasCardSale) ...[
                    // Card sale payment
                    _row('Card', totalUsed.toStringAsFixed(2), receiptStyle),
                    _row('Balance', customerBalance.toStringAsFixed(2), balanceStyle),
                  ] else ...[
                    // Cash sale payment
                    _row(paymentModeName, totalPaid.toStringAsFixed(2), receiptStyle),
                    _row('Change', change.toStringAsFixed(2), receiptStyle),
                  ],

                  const Divider(),

                  // Customer details (only for card sales)
                  if (wasCardSale) ...[
                    _row('Customer:', customerName, receiptStyle),
                    _row('Card No:', cardMask, receiptStyle),
                    _row('Account Type:', accountType, receiptStyle),
                    if (vehicleNumber != 'No Equipment')
                      _row('Vehicle:', vehicleNumber, receiptStyle),
                    const Divider(),
                  ],

                  // Transaction details
                  _row('Date', ticket['ticketCreationDate'] ?? 'N/A', receiptStyle),
                  _row('Served By', ticket['staffName'] ?? 'N/A', receiptStyle),
                  _row('Reprinted By', widget.user.staffName, receiptStyle),
                  const Divider(),

                  // Approval section (only for card sales)
                  if (wasCardSale) ...[
                    const Center(
                      child: Text('APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Center(child: Text('Cardholder acknowledges receipt')),
                    const Center(child: Text('of goods/services in the amount')),
                    const Center(child: Text('shown above.')),
                    const SizedBox(height: 10),
                    const Center(child: Text('Cardholder Signature')),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Center(
                    child: Text('THANK YOU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Center(child: Text('CUSTOMER COPY - REPRINT')),
                  const SizedBox(height: 4),
                  const Center(child: Text('Powered by Sahara FCS', style: TextStyle(fontSize: 11))),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _printReceipt,
          backgroundColor: ColorsUniversal.buttonsColor,
          child: const Icon(Icons.print, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            child: Text(value, style: style, textAlign: TextAlign.right, softWrap: true),
          ),
        ],
      ),
    );
  }
}
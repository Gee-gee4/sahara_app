// lib/pages/card_details_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/card_details_printer_helper.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class CardDetailsPage extends StatefulWidget {
  final StaffListModel user;
  final CustomerAccountDetailsModel details;
  final String termNumber;
  final String? companyName;
  final String? channelName;

  const CardDetailsPage({
    super.key,
    required this.user,
    required this.details,
    required this.termNumber,
    this.companyName,
    this.channelName,
  });

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  Future<void> _printCardDetails() async {
    await CardDetailsPrinterHelper.printCardDetails(
      context: context,
      user: widget.user,
      details: widget.details,
      termNumber: widget.termNumber,
      companyName: widget.companyName,
      channelName: widget.channelName,
    );
  }

  void _showEndTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(backgroundColor: Colors.white,
        title: const Text('Exit Page'),
        content: const Text('You will lose all progress if you exit from this page', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
            child: Text('OK', style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _divider() {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Divider(thickness: 1));
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = TextStyle(fontFamily: 'Courier', fontSize: 14);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          _showEndTransactionDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Card Details Receipt', style: TextStyle(color: Colors.white70)),
          centerTitle: true,
          backgroundColor: ColorsUniversal.appBarColor,
          leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
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
                  Center(
                    child: Text(
                      widget.companyName ?? 'SAHARA FCS',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(child: Text(widget.channelName ?? 'Station')),
                  const SizedBox(height: 15),
                  const Center(
                    child: Text('CARD DETAILS', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 8),
                  Text('TERM# ${widget.termNumber}', style: receiptStyle),
                  Divider(),

                  _row('Customer:', widget.details.customerName, receiptStyle),
                  _row('Card:', widget.details.mask ?? 'N/A', receiptStyle),
                  _row('Agreement:', widget.details.agreementDescription, receiptStyle),
                  _row('Account Type:', widget.details.accountCreditTypeName, receiptStyle),
                  _row('Card Balance:', widget.details.customerAccountBalance.toStringAsFixed(2), receiptStyle),
                  _row('Status:', widget.details.customerIsActive ? 'Active' : 'Inactive', receiptStyle),

                  Divider(),
                  Divider(),

                  Text('Account Policies:', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                  _row('Start Time:', widget.details.startTime, receiptStyle),
                  _row('End Time:', widget.details.endTime, receiptStyle),
                  _row('Frequency:', widget.details.frequecy.toString(), receiptStyle),
                  _row('Frequency Period:', widget.details.frequencyPeriod ?? 'null', receiptStyle),

                  Text('Fueling Days:', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                  Text(widget.details.dateToFuel, style: receiptStyle),

                  Divider(),
                  if (widget.details.customerVehicles.isNotEmpty) ...[
                    Divider(),
                    Text('Customer Vehicles:', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    for (final vehicle in widget.details.customerVehicles) ...[
                      _row('Reg No:', vehicle.regNo, receiptStyle),
                      _row('Fuel Type:', vehicle.fuelType, receiptStyle),
                      _row('Tank Capacity:', vehicle.tankCapacity, receiptStyle),
                      _row('Start Time:', vehicle.startTime, receiptStyle),
                      _row('End Time:', vehicle.endTime, receiptStyle),
                      Text('Fueling Days:', style: receiptStyle),
                      Text(vehicle.fuelDays, style: receiptStyle),
                      Divider(),
                    ],
                  ],

                  Divider(),

                  _row('Date', DateTime.now().toString().substring(0, 19), receiptStyle),
                  _row('Served By', widget.user.staffName, receiptStyle),

                  Divider(),

                  const Center(
                    child: Text('APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Divider(),
                  const Center(child: Text('Cardholder Signature')),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('THANK YOU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _printCardDetails,
          backgroundColor: ColorsUniversal.buttonsColor,
          child: Icon(Icons.print, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _row(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: style),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

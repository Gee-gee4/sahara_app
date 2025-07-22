import 'package:flutter/material.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class CardDetailsPage extends StatelessWidget {
  final StaffListModel user;
  final CustomerAccountDetailsModel details;

  const CardDetailsPage({super.key, required this.user, required this.details});

  Widget _divider() {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Divider(thickness: 1));
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = TextStyle(fontFamily: 'Courier', fontSize: 14);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details Receipt', style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomePage(user: user)),
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
                const Center(
                  child: Text('SAHARA FCS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Center(child: Text('CMB Station')),
                const SizedBox(height: 15),
                const Center(
                  child: Text('CARD DETAILS', style: TextStyle(decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 8),
                Text('TERM# 8458cn34e3kf343', style: receiptStyle),
        
                Divider(),
        
                _row('Customer:', details.customerName, receiptStyle),
                _row('Card:', details.mask ?? 'N/A', receiptStyle),
                _row('Agreement:', details.agreementTypeName, receiptStyle),
                _row('Account Type:', details.accountCreditTypeName, receiptStyle),
                _row('Card Balance:', details.customerAccountBalance.toString(), receiptStyle),
                _row('Status:', details.customerIsActive ? 'Active' : 'Inactive', receiptStyle),
        
                Divider(),
                // const SizedBox(height: 1),
                Divider(),
                Text('Products & Discounts:',style: receiptStyle.copyWith(fontWeight: FontWeight.bold),),
                for (final product in details.products) ...[
                  _row('Product Name:', product.productVariationName, receiptStyle),
                  _row('Product Price:', product.productPrice.toStringAsFixed(2), receiptStyle),
                  _row('Product Discount:', product.productDiscount.toStringAsFixed(2), receiptStyle),
                  _divider(),
                ],
        
                Divider(),
        
                Text('Account Policies:', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                _row('Start Time:', details.startTime, receiptStyle),
                _row('End Time:', details.endTime, receiptStyle),
                _row('Frequency:', details.frequecy.toString(), receiptStyle),
                _row('Frequency Period:', details.frequencyPeriod ?? 'null', receiptStyle),
        
                Divider(),
                Text('Fueling Days:', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                Text(details.dateToFuel, style: receiptStyle),
        
                Divider(),
        
                // const SizedBox(height: 3),
                // Divider(),
                _row('Date', DateTime.now().toString().substring(0, 19), receiptStyle),
                _row('Served By', user.staffName, receiptStyle),
        
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

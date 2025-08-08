// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/transaction_model.dart';
import 'package:sahara_app/modules/transaction_module.dart';
import 'package:sahara_app/pages/cart_page.dart';
import 'package:sahara_app/utils/color_hex.dart';

// IconButton cartIconButton(BuildContext context, CartModule cartModuleBox) {
//   return IconButton(
//     onPressed: () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => CartPage(user: ,)),
//       );
//     },
//     icon: Badge(
//       offset: Offset(6, -6),
//       backgroundColor: hexToColor('005954'),
//       isLabelVisible: cartModuleBox.cartItems.isNotEmpty,
//       label: Text(cartModuleBox.cartItems.length.toString()),
//       child: Icon(Icons.shopping_cart),
//     ),
//   );
// }

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, required this.pumpId});
  final String pumpId;
  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  // final CartStorage cartModuleBox = CartStorage.instance();

  final TransactionModule _transactionModule = TransactionModule();
  List<TransactionModel> transactions = [];
  List<String> nozzles = [];
  String? selectedNozzle;
  bool isFetching = false;

  // @override
  // void initState() {
  //   super.initState();
  //   fetchAndSetTransactions();
  //   cartModuleBox.addListener(() {
  //     if (mounted) {
  //       setState(() {});
  //     }
  //   });
  // }

  Future<void> fetchAndSetTransactions() async {
    setState(() {
      isFetching = true;
    });

    final items =
        widget.pumpId == 'all'
            ? await _transactionModule.fetchAllTransactions()
            : await _transactionModule.fetchTransactions(widget.pumpId);

    final nozzleList = items.map((tx) => tx.nozzle).toSet().toList();

    setState(() {
      if (mounted) {
        // Add this check
        transactions = items;
        nozzles = nozzleList;
        isFetching = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions =
        (selectedNozzle == null || selectedNozzle == 'all')
            ? transactions
            : transactions.where((tx) => tx.nozzle == selectedNozzle).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: hexToColor('d7eaee'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
        //   cartIconButton(context, cartModuleBox),
        //   if (nozzles.isNotEmpty)
        //     Padding(
        //       padding: const EdgeInsets.only(right: 12.0),
        //       child: SizedBox(
        //         width: 150,
        //         child: DropdownButtonHideUnderline(
        //           child: DropdownButton2<String>(
        //             isExpanded: true,
        //             value: selectedNozzle ?? 'all',
        //             dropdownStyleData: DropdownStyleData(
        //               padding: const EdgeInsets.symmetric(vertical: 6),
        //               decoration: BoxDecoration(
        //                 borderRadius: BorderRadius.circular(25),
        //                 color: hexToColor('d7eaee'),
        //               ),
        //             ),
        //             buttonStyleData: ButtonStyleData(
        //               decoration: BoxDecoration(
        //                 color: Colors.teal[50],
        //                 borderRadius: BorderRadius.circular(16),
        //               ),
        //               padding: const EdgeInsets.symmetric(horizontal: 16),
        //             ),
        //             iconStyleData: const IconStyleData(
        //               icon: Icon(Icons.filter_list, color: Colors.black),
        //             ),
        //             style: const TextStyle(fontSize: 16, color: Colors.black),
        //             onChanged: (value) {
        //               setState(() {
        //                 selectedNozzle = value == 'all' ? null : value;
        //               });
        //             },
        //             items: [
        //               DropdownMenuItem(
        //                 value: 'all',
        //                 child: Text("All Nozzles"),
        //               ),
        //               ...nozzles.map(
        //                 (noz) => DropdownMenuItem(
        //                   value: noz,
        //                   child: Text("Nozzle $noz"),
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        ],
      ),
      body: Column(
        children: [
          if (isFetching)
            LinearProgressIndicator(
              color: hexToColor('005954'),
              backgroundColor: hexToColor('9fd8e1'),
            ),
          Expanded(
            child:
                filteredTransactions.isEmpty
                    ? Center(child: Text(" "))
                    : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        TransactionModel transaction =
                            filteredTransactions[index];
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                color: Colors.teal[50],
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  splashColor: Colors.teal[50],
                                  onTap:(){},
                                      // cartModuleBox.cartItems.isNotEmpty
                                      //     // add to cart
                                      //     ? () {
                                      //       _addToCart(transaction);
                                      //     }
                                      //     // post direct
                                      //     : () {
                                      //       showDialog(
                                      //         context: context,
                                      //         barrierDismissible: false,
                                      //         builder:
                                      //             (context) => AlertBoxTrans(
                                      //               cartItemTrans: [
                                      //                 transaction
                                      //                     .toCartItemModel(),
                                      //               ],
                                      //             ),
                                      //       );
                                      //     },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    height: 100,
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              transaction.productName,
                                              style: TextStyle(fontSize: 18),
                                            ),
                                            Text(
                                              transaction.nozzle,
                                              style: TextStyle(fontSize: 25),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              transaction.dateTimeSold,
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              "Ksh ${transaction.price}",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "Litres ${transaction.volume}",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "Ksh ${transaction.totalAmount.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16,
                              bottom: 10,
                              child: IconButton(
                                onPressed: () {
                                  // final CartItemModel cartItem = CartItemModel(
                                  //   productId: transaction.productId ?? '',
                                  //   productName: transaction.productName,
                                  //   price: transaction.price,
                                  //   quantity: transaction.volume,
                                  //   totalAmount: transaction.totalAmount
                                  // );
                                  // _addToCart(transaction);
                                  // print('${cartModuleBox.cartItems}');
                                },
                                icon: Icon(Icons.add_shopping_cart),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // void _addToCart(TransactionModel transaction) {
  //   final wasAdded = cartModuleBox.addCartItem(transaction.toCartItemModel());
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           wasAdded
  //               ? Text('Product added successfully')
  //               : Text('Already exists!'),
  //       duration: Duration(milliseconds: 1000),
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       backgroundColor: wasAdded ? hexToColor('005954') : Colors.grey,
  //     ),
  //   );
  // }
}

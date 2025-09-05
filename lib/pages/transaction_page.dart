import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_model.dart';
import 'package:sahara_app/modules/transaction_module.dart';
import 'package:sahara_app/pages/cart_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, required this.pumpId, required this.user});
  final String pumpId;
  final StaffListModel user;
  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TransactionModule _transactionModule = TransactionModule();
  List<TransactionModel> transactions = [];
  List<String> nozzles = [];
  String? selectedNozzle;
  bool isFetching = false;
    final CartStorage cartStorage = CartStorage();


  @override
  void initState() {
    super.initState();
    // automatically fetch transactions when page loads
    fetchAndSetTransactions();

      // Listener for cart changes
    cartStorage.addListener(_onCartChanged);
  }

    @override
  void dispose() {
    // Remove listener to prevent memory leaks
    cartStorage.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {}); // Refresh UI when cart changes
    }
  }

  Future<void> fetchAndSetTransactions() async {
    setState(() {
      isFetching = true;
    });

    print('🔍 TransactionPage: Fetching transactions for pump: ${widget.pumpId}');

    final items = widget.pumpId == 'all'
        ? await _transactionModule.fetchAllTransactions()
        : await _transactionModule.fetchTransactions(widget.pumpId);

    final nozzleList = items.map((tx) => tx.nozzle).toSet().toList();

    setState(() {
      if (mounted) {
        transactions = items;
        nozzles = nozzleList;
        isFetching = false;

        print('✅ TransactionPage: Loaded ${transactions.length} transactions');
        print('  Nozzles found: $nozzles');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final filteredTransactions = (selectedNozzle == null || selectedNozzle == 'all')
        ? transactions
        : transactions.where((tx) => tx.nozzle == selectedNozzle).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white70),
        backgroundColor: ColorsUniversal.appBarColor,
        actions: [
          // Nozzle filter dropdown in AppBar
          if (nozzles.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedNozzle,
                  hint: Text('Nozzle', style: TextStyle(color: Colors.white)),
                  dropdownColor: ColorsUniversal.background,
                  iconEnabledColor: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Nozzles')),
                    ...nozzles.map((nozzle) => DropdownMenuItem(value: nozzle, child: Text('Nozzle $nozzle'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedNozzle = value;
                    });
                  },
                ),
              ),
            ),

          // Refresh button after dropdown
          IconButton(
            onPressed: fetchAndSetTransactions,
            icon: Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh Transactions',
          ),
        ],
      ),

      body: isFetching
          ? Center(
              child: SpinKitCircle(
                size: 70,
                duration: Duration(milliseconds: 1000),
                itemBuilder: (context, index) {
                  final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
                  final color = colors[index % colors.length];
                  return DecoratedBox(
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  );
                },
              ),
            )
          : filteredTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    isFetching ? 'Loading transactions...' : 'No transactions found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  if (!isFetching) ...[
                    SizedBox(height: 8),
                    Text('Try refreshing or check your time range', style: TextStyle(color: Colors.grey[500])),
                  ],
                ],
              ),
            )
          : ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                TransactionModel transaction = filteredTransactions[index];
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        color: Colors.brown[100],
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          splashColor: ColorsUniversal.fillWids,
                          onTap: () {},
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            height: 100,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    //PRODUCT NAME
                                    Text(transaction.productName, style: TextStyle(fontSize: 18)),

                                    //NOZZLE
                                    Text(
                                      'Nozzle ${transaction.nozzle}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    //DATE
                                    Text(
                                      transaction.dateTimeSold,
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),

                                    //PRICE
                                    Text(
                                      "Ksh ${transaction.price}/L",
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
                                    ),

                                    //VOLUME-QUANTITY
                                    Text(
                                      "${transaction.volume}L",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    //TOTAL PRICE
                                    Text(
                                      "Total: Ksh ${transaction.totalAmount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green[900],
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
                          try {
                            // Add the transaction to cart storage
                            cartStorage.addToCart(
                              int.parse(transaction.productId ?? '0'), // productId (int)
                              transaction.productName, // name (String)
                              transaction.price, // unitPrice (double)
                              transaction.volume, // quantity (double) - fixed quantity from transaction
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${transaction.productName} added to cart'),
                                duration: Duration(milliseconds: 700),
                                backgroundColor: hexToColor('8f9c68'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add to cart'),
                                duration: Duration(milliseconds: 700),
                                backgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.add_shopping_cart),
                        tooltip: 'Add to Cart',
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartPage(user: widget.user)),
          ).then((_) => setState(() {})); // Refresh when coming back
        },
        backgroundColor: ColorsUniversal.buttonsColor,
        child: Badge(
          isLabelVisible: cartStorage.cartItems.isNotEmpty,
          label: Text('${cartStorage.cartItems.length}'),
          offset: Offset(9, -9),
          backgroundColor: ColorsUniversal.appBarColor,
          child: const Icon(Icons.shopping_cart, color: Colors.white70),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

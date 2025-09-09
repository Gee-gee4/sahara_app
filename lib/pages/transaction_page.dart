import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_model.dart';
import 'package:sahara_app/modules/transaction_module.dart';
import 'package:sahara_app/pages/cart_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

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
  String? errorMessage;
  final CartStorage cartStorage = CartStorage();

  @override
  void initState() {
    super.initState();
    // automatically fetch transactions when page loads
    fetchAndSetTransactions();
    cartStorage.addListener(_onCartChanged);
  }

  @override
  void dispose() {
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
      errorMessage = null;
    });

    print('🔍 TransactionPage: Fetching transactions for pump: ${widget.pumpId}');

    try {
      final response = widget.pumpId == 'all'
          ? await _transactionModule.fetchAllTransactions()
          : await _transactionModule.fetchTransactions(widget.pumpId);

      setState(() {
        isFetching = false;

        if (response.isSuccessfull) {
          transactions = response.body;
          nozzles = transactions.map((tx) => tx.nozzle).toSet().toList();
          print('✅ TransactionPage: Loaded ${transactions.length} transactions');
          print('  Nozzles found: $nozzles');
        } else {
          errorMessage = response.message;
          transactions = [];
          nozzles = [];

          // Show error dialog for any network connectivity issues
          if (_isNetworkError(errorMessage!)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog('No Internet Connectivity. Please check your connection and try again.');
            });
          } else {
            // Show the specific error message for non-network errors
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(errorMessage!);
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        isFetching = false;
        errorMessage = e.toString();
        transactions = [];
        nozzles = [];
      });

      // Show error dialog for any network connectivity issues from exceptions
      if (_isNetworkError(e.toString())) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog('No Internet Connectivity. Please check your connection and try again.');
        });
      } else {
        // Show the specific error message for non-network errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog('An unexpected error occurred: ${e.toString()}');
        });
      }
    }
  }

  bool _isNetworkError(String errorMessage) {
    final lowerCaseMessage = errorMessage.toLowerCase();

    return lowerCaseMessage.contains('no internet connectivity') ||
        lowerCaseMessage.contains('connection reset by peer') ||
        lowerCaseMessage.contains('connection refused') ||
        lowerCaseMessage.contains('failed host lookup') ||
        lowerCaseMessage.contains('socket exception') ||
        lowerCaseMessage.contains('network is unreachable') ||
        lowerCaseMessage.contains('timed out') ||
        lowerCaseMessage.contains('clientexception') ||
        lowerCaseMessage.contains('ioexception') ||
        lowerCaseMessage.contains('handshake exception');
  }

  void _showErrorDialog(String message) {
    final isNetworkError = _isNetworkError(message);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(isNetworkError ? Icons.wifi_off : Icons.error_outline, color: Colors.orange),
            SizedBox(width: 3),
            Text(isNetworkError ? 'Connection Problem' : 'Error'),
          ],
        ),
        content: Text(
          isNetworkError ? 'No Internet Connectivity. Please check your connection and try again.' : message,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: ColorsUniversal.buttonsColor)),
          ),
          if (isNetworkError)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                fetchAndSetTransactions(); // Retry
              },
              child: Text('Retry', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 18)),
            ),
        ],
      ),
    );
  }

  String _getUserFriendlyErrorMessage(String technicalMessage) {
    if (_isNetworkError(technicalMessage)) {
      return 'No Internet Connectivity.';
    } else if (technicalMessage.contains('404')) {
      return 'The requested information was not found.';
    } else if (technicalMessage.contains('401') || technicalMessage.contains('403')) {
      return 'Access denied. Please contact support.';
    } else if (technicalMessage.contains('500')) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else {
      return 'Something went wrong. Please try again or contact support.';
    }
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
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getUserFriendlyErrorMessage(errorMessage!),
                    style: TextStyle(fontSize: 16, color: ColorsUniversal.appBarColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 40, width: 95, child: myButton(context, fetchAndSetTransactions, 'Retry')),
                ],
              ),
            )
          : filteredTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transactions found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Try refreshing or check your time range', style: TextStyle(color: Colors.grey[500])),
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
                              fixedTotal: transaction.totalAmount,
                              isTransaction: true
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

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/models/pump_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/pumps_module.dart';
import 'package:sahara_app/pages/transaction_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/pump_card.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class FuelPage extends StatefulWidget {
  const FuelPage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  final PumpsModule _pumpsModule = PumpsModule();
  List<PumpModel> pumps = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPumps();
  }

  Future<void> _loadPumps() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _pumpsModule.fetchPumps();

    setState(() {
      isLoading = false;

      if (response.isSuccessfull) {
        pumps = response.body;
      } else {
        errorMessage = response.message;
        pumps = []; // Clear pumps on error
      }
    });

    // Show error dialog if there's an error
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(errorMessage!);
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          if (message.contains('No Internet Connectivity'))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadPumps(); // Retry
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool narrowPhone = MediaQuery.of(context).size.width < 365;

    return Scaffold(
      extendBody: true,
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionPage(pumpId: 'all', user: widget.user),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              width: 170,
              decoration: BoxDecoration(color: ColorsUniversal.fillWids, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('All Transactions'),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionPage(pumpId: 'all', user: widget.user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
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
                    errorMessage!,
                    style: TextStyle(fontSize: 16, color: ColorsUniversal.appBarColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 40, width: 95, child: myButton(context, _loadPumps, 'Retry')),
                ],
              ),
            )
          : pumps.isEmpty
          ? const Center(child: Text('No pumps available', style: TextStyle(fontSize: 16)))
          : GridView.builder(
              itemCount: pumps.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: narrowPhone ? .8 : .9,
              ),
              itemBuilder: (context, index) {
                final pumpCurrent = pumps[index];
                return Padding(
                  padding: EdgeInsets.all(narrowPhone ? 0 : 8),
                  child: PumpCard(
                    imagePath: 'assets/images/pump cropped.png',
                    imageWidth: 48,
                    title: pumpCurrent.pumpName,
                    model: pumpCurrent,
                    buttonName: 'Transactions',
                    cardOnTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionPage(pumpId: pumpCurrent.pumpId, user: widget.user),
                        ),
                      );
                    },
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionPage(pumpId: pumpCurrent.pumpId, user: widget.user),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

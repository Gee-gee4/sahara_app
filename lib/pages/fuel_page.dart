import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/models/pump_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/pumps_module.dart';
import 'package:sahara_app/pages/operation_mode_settings_page.dart';
import 'package:sahara_app/pages/transaction_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/pump_card.dart';

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
    // Determine the type of error for better UI
    String title;
    IconData icon;
    Color iconColor;
    List<Widget> actions = [];

    if (message.contains('No Internet Connection') || message.contains('Connection')) {
      title = 'Connection Problem';
      icon = Icons.wifi_off;
      iconColor = Colors.orange;
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _loadPumps(); // Retry
          },
          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
          child: Text('Try Again', style: TextStyle(color: Colors.white)),
        ),
      ];
    } else if (message.contains('Station') && message.contains('not found')) {
      title = 'Station Not Found';
      icon = Icons.location_off;
      iconColor = ColorsUniversal.appBarColor;
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to settings to fix station name
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OperationModeSettingsPage(user: widget.user,),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
          child: Text('Open Settings', style: TextStyle(color: Colors.white)),
        ),
      ];
    } else if (message.contains('Authentication') || message.contains('Access denied')) {
      title = 'Access Problem';
      icon = Icons.lock;
      iconColor = Colors.red;
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _loadPumps(); // Retry
          },
          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
          child: Text('Try Again', style: TextStyle(color: Colors.white)),
        ),
      ];
    } else if (message.contains('Server') || message.contains('temporarily unavailable')) {
      title = 'Server Problem';
      icon = Icons.cloud_off;
      iconColor = Colors.orange;
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _loadPumps(); // Retry
          },
          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
          child: Text('Try Again', style: TextStyle(color: Colors.white)),
        ),
      ];
    } else {
      title = 'Error';
      icon = Icons.error_outline;
      iconColor = Colors.red;
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _loadPumps(); // Retry
          },
          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
          child: Text('Try Again', style: TextStyle(color: Colors.white)),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            // if (message.contains('Station') && message.contains('not found')) ...[
            //   // Container(
            //   //   padding: EdgeInsets.all(12),
            //   //   decoration: BoxDecoration(
            //   //     color: ColorsUniversal.fillWids,
            //   //     borderRadius: BorderRadius.circular(8),
            //   //     border: Border.all(color: ColorsUniversal.buttonsColor),
            //   //   ),
            //   //   child: Row(
            //   //     children: [
            //   //       Icon(Icons.info, color: ColorsUniversal.buttonsColor, size: 20),
            //   //       SizedBox(width: 8),
            //   //       Expanded(
            //   //         child: Text(
            //   //           'Check your station name in the settings page.',
            //   //           style: TextStyle(
            //   //             fontSize: 14,
                          
            //   //           ),
            //   //         ),
            //   //       ),
            //   //     ],
            //   //   ),
            //   // ),
            // ],
          ],
        ),
        actions: actions,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Pumps Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No fuel pumps found for this station',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPumps,
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text('Refresh', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsUniversal.buttonsColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    IconData errorIcon;
    Color errorColor;
    
    if (errorMessage!.contains('No Internet Connection')) {
      errorIcon = Icons.wifi_off;
      errorColor = Colors.orange;
    } else if (errorMessage!.contains('Station') && errorMessage!.contains('not found')) {
      errorIcon = Icons.location_off;
      errorColor = ColorsUniversal.appBarColor;
    } else {
      errorIcon = Icons.error_outline;
      errorColor = ColorsUniversal.appBarColor;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorIcon,
              size: 30
            ,
              color: errorColor,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to Load Pumps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPumps,
              icon: Icon(Icons.refresh, color: Colors.white, size: 18),
              label: Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsUniversal.buttonsColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitCircle(
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
                  SizedBox(height: 16),
                  Text(
                    'Loading pumps...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? _buildErrorState()
              : pumps.isEmpty
                  ? _buildEmptyState()
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
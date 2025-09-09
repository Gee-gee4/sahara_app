import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:sahara_app/pages/login_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<StaffListModel> staffList = [];

  @override
  void initState() {
    super.initState();
    loadStaffListFromHive();
  }

  void loadStaffListFromHive() {
    final box = Hive.box('staff_list');
    final storedList = box.get('staffList', defaultValue: []) as List;
    setState(() {
      staffList = storedList
          .map((e) => StaffListModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<void> refreshStaffList() async {
    // Store context locally before async operations
    final currentContext = context;
    if (!currentContext.mounted) return;

    // Show loading indicator
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SpinKitCircle(
          size: 70,
          duration: const Duration(milliseconds: 1000),
          itemBuilder: (context, index) {
            final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
            final color = colors[index % colors.length];
            return DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            );
          },
        ),
      ),
    );

    try {
      // Fetch from API
      final deviceId = await getSavedOrFetchDeviceId();
      final newStaffListRes = await StaffListService.fetchStaffList(deviceId);

      // Close the loading dialog first
      if (currentContext.mounted) Navigator.pop(currentContext);

      // Check if the fetch was successful
      if (!newStaffListRes.isSuccessfull) {
        if (currentContext.mounted) {
          // Check for specific error types
          if (newStaffListRes.message.contains('No Internet Connectivity')) {
            // Show internet connectivity error dialog
            showDialog(
              context: currentContext,
              builder: (_) => AlertDialog(
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    Icon(Icons.wifi_off, color: ColorsUniversal.appBarColor, size: 24),
                    SizedBox(width: 8),
                    Text('No Internet Connection'),
                  ],
                ),
                content: Text(
                  'Internet connection is required to sync users. Please check your connection and try again.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(currentContext),
                    child: Text('OK', style: TextStyle(color: ColorsUniversal.buttonsColor,fontSize: 18)),
                  ),
                ],
              ),
            );
          } else {
            // Show general error dialog
            showDialog(
              context: currentContext,
              builder: (_) => AlertDialog(
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 24),
                    SizedBox(width: 8),
                    Text('Sync Failed'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to sync users from server:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        newStaffListRes.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(currentContext),
                    child: Text('OK', style: TextStyle(color: ColorsUniversal.buttonsColor)),
                  ),
                ],
              ),
            );
          }
        }
        return; // Stop execution here
      }

      // Success! Extract the staff list
      final newStaffList = newStaffListRes.body;

      // Save to Hive
      final box = Hive.box('staff_list');
      final staffAsMaps = newStaffList.map((e) => e.toJson()).toList();
      await box.put('staffList', staffAsMaps);

      // Reload UI from Hive
      loadStaffListFromHive();

      // Show success feedback
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Successfully synced users!'),
                // ${newStaffList.length} 
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: hexToColor('8f9c68'),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      print('✅ Staff list synced successfully: ${newStaffList.length} users');
      
    } catch (e) {
      // Close loading dialog if still open
      if (currentContext.mounted) {
        try {
          Navigator.pop(currentContext);
        } catch (_) {
          // Dialog might already be closed
        }
      }

      // Show error feedback for unexpected errors
      if (currentContext.mounted) {
        showDialog(
          context: currentContext,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('Unexpected Error'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'An unexpected error occurred while syncing:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    e.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(currentContext),
                child: Text('OK', style: TextStyle(color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }
      
      debugPrint('❌ Error refreshing staff list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        title: const Text('Terminal Users', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: refreshStaffList,
            icon: const Icon(Icons.people, color: Colors.white, size: 30),
            tooltip: 'Sync users',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select User', style: TextStyle(fontSize: 16)),
                Text(
                  '${staffList.length} users',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (staffList.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the sync button to load users',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ColorsUniversal.buttonsColor,
                          child: Text(
                            staff.staffName.isNotEmpty 
                                ? staff.staffName[0].toUpperCase() 
                                : 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          staff.staffName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        // subtitle: Text(
                        //   'Staff ID: ${staff.staffId}',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),
                        // trailing: Icon(
                        //   Icons.arrow_forward_ios,
                        //   size: 16,
                        //   color: Colors.grey[400],
                        // ),
                        tileColor: Colors.brown[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(username: staff.staffName),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
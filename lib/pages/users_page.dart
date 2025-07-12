import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
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
      final deviceId = '044ba7ee5cdd86c5'; // Or load from SharedPrefs
      final newStaffList = await StaffListService.fetchStaffList(deviceId);

      // Save to Hive
      final box = Hive.box('staff_list');
      final staffAsMaps = newStaffList.map((e) => e.toJson()).toList();
      await box.put('staffList', staffAsMaps);

      // Reload UI from Hive
      loadStaffListFromHive();

      // Close the loading dialog
      if (currentContext.mounted) Navigator.pop(currentContext);

      // Show success feedback
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: const Text('Successfully synced users!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: hexToColor('8f9c68'),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Close dialog if still mounted
      if (currentContext.mounted) Navigator.pop(currentContext);

      // Show error feedback if still mounted
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.grey,
          ),
        );
      }
      debugPrint('Error refreshing staff list: $e');
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
            const Text('Select User', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: staffList.length,
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Text(
                        staff.staffName,
                        style: const TextStyle(fontSize: 16),
                      ),
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

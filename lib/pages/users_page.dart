import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:sahara_app/pages/login_page.dart';
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
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
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
    if (context.mounted) Navigator.pop(context);

    // ✅ Show "Synced" SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Synced users!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // Close dialog and show error
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to refresh staff list'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      leading: Text(staff.staffName, style: const TextStyle(fontSize: 16)),
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


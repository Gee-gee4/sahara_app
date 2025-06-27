// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sahara_app/modules/resource_service.dart';
import 'package:sahara_app/pages/pos_settings_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  final TextEditingController _resourceTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('Resource Settings'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Name',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            reusableTextField(
              'Enter Theme Name',
              null,
              true,
              _resourceTextController,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: myButton(context, () async {
                    final resource = _resourceTextController.text
                        .trim()
                        .toLowerCase();
                    if (resource.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a resource name')),
                      );
                      return;
                    }

                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                           Center(child: CircularProgressIndicator(color: ColorsUniversal.buttonsColor,)),
                    );

                    final success = await ResourceService.fetchAndSaveConfig(
                      resource,
                    );
                    Navigator.pop(context); // close loading

                    if (success) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PosSettingsPage()),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text(
                            'Could not fetch configuration for that resource.',
                          ),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  }, 'APPLY'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/modules/resource_service.dart';
import 'package:sahara_app/pages/pos_settings_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
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
                    // Store context locally before async operations
                    final currentContext = context;
                    if (!currentContext.mounted) return;

                    final resource = _resourceTextController.text.trim().toLowerCase();
                    if (resource.isEmpty) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(content: Text('Please enter a resource name')),
                      );
                      return;
                    }

                    // Show loading
                    showDialog(
                      context: currentContext,
                      barrierDismissible: false,
                      builder: (_) => Center(
                        child: SpinKitCircle(
                          size: 70,
                          duration: Duration(milliseconds: 1000),
                          itemBuilder: (context, index) {
                            final colors = [
                              ColorsUniversal.buttonsColor,
                              ColorsUniversal.fillWids,
                            ];
                            final color = colors[index % colors.length];
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      ),
                    );

                    try {
                      final responseModel = await ResourceService.fetchAndSaveConfig(resource);
                      
                      // Close loading dialog
                      if (currentContext.mounted) Navigator.pop(currentContext);

                      if (!currentContext.mounted) return;

                      if (responseModel.isSuccessfull) {
                        // Success - navigate to PosSettingsPage
                        Navigator.push(
                          currentContext,
                          MaterialPageRoute(builder: (_) => const PosSettingsPage()),
                        );
                        
                        // Show success message
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text(responseModel.message),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: hexToColor('8f9c68'),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } else {
                        // Show error dialog with the specific error message
                        showDialog(
                          context: currentContext,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Row(
                              children: [
                                Icon(
                                  responseModel.message.contains('Internet') 
                                    ? Icons.wifi_off 
                                    : Icons.error_outline,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Error'),
                              ],
                            ),
                            content: Text(responseModel.message),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(currentContext),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      // Close loading dialog if still open
                      if (currentContext.mounted) Navigator.pop(currentContext);
                      
                      // Show generic error
                      if (currentContext.mounted) {
                        showDialog(
                          context: currentContext,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Unexpected Error'),
                              ],
                            ),
                            content: Text('An unexpected error occurred: ${e.toString()}'),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(currentContext),
                              ),
                            ],
                          ),
                        );
                      }
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
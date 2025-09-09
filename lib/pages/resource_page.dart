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
  
  // Helper method to show error dialog
  void _showErrorDialog(BuildContext context, {required String title, required String message, IconData? icon}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            // Icon(
            //   icon ?? Icons.error_outline,
            //   color: ColorsUniversal.appBarColor,
            // ),
            // const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message,style: TextStyle(fontSize: 16),),
        actions: [
          TextButton(
            child: Text('OK',style: TextStyle(color: ColorsUniversal.buttonsColor,fontSize: 18),),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Helper method to get user-friendly error message
  String _getUserFriendlyErrorMessage(String technicalMessage) {
    if (technicalMessage.contains('404')) {
      return 'The resource name was not found. Please check the spelling and try again.';
    } else if (technicalMessage.toLowerCase().contains('internet') || 
               technicalMessage.toLowerCase().contains('connection') ||
               technicalMessage.toLowerCase().contains('network')) {
      return 'No internet connection. Please check your network settings and try again.';
    } else if (technicalMessage.contains('timed out')) {
      return 'The request took too long. Please check your internet connection and try again.';
    } else if (technicalMessage.contains('401') || technicalMessage.contains('403')) {
      return 'Access denied. Please contact support if you believe this is an error.';
    } else if (technicalMessage.contains('500')) {
      return 'Server is temporarily unavailable. Please try again in a few moments.';
    } else {
      return 'Something went wrong. Please try again. If the problem persists, contact support.';
    }
  }

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
            const Text(
              'Resource Name',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            reusableTextField(
              'Enter Resource Name', // Changed from 'Enter Theme Name' for consistency
              null,
              true,
              _resourceTextController,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Enter the exact name provided by your administrator',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: myButton(context, () async {
                    final currentContext = context;
                    if (!currentContext.mounted) return;

                    final resource = _resourceTextController.text.trim().toLowerCase();
                    if (resource.isEmpty) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(content: Text('Please enter a resource name'),backgroundColor: Colors.grey,),
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
                          duration: const Duration(milliseconds: 1000),
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
                        // Show user-friendly error message
                        final friendlyMessage = _getUserFriendlyErrorMessage(responseModel.message);
                        _showErrorDialog(
                          currentContext,
                          title: 'Unable to fetch resources',
                          message: friendlyMessage,
                          icon: responseModel.message.toLowerCase().contains('internet') 
                              ? Icons.wifi_off 
                              : Icons.search_off, // Different icon for "not found" vs "no internet"
                        );
                      }
                    } catch (e) {
                      // Close loading dialog if still open
                      if (currentContext.mounted) Navigator.pop(currentContext);
                      
                      // Show user-friendly error message for unexpected errors
                      if (currentContext.mounted) {
                        final friendlyMessage = _getUserFriendlyErrorMessage(e.toString());
                        _showErrorDialog(
                          currentContext,
                          title: 'Unexpected Error',
                          message: friendlyMessage,
                          icon: Icons.error_outline,
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
// lib/pages/operation_mode_settings_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/pages/pos_settings_helper.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';

class OperationModeSettingsPage extends StatefulWidget {
  const OperationModeSettingsPage({super.key});

  @override
  State<OperationModeSettingsPage> createState() => _OperationModeSettingsPageState();
}

class _OperationModeSettingsPageState extends State<OperationModeSettingsPage> {
  OperationMode _currentMode = OperationMode.manual;
  OperationMode _newMode = OperationMode.manual;
  bool _isLoading = false;

  // Controllers for auto mode settings
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _fetchingTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
    _loadAutoModeSettings();
  }

  Future<void> _loadCurrentMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the correct key from SharedPrefsHelper
    final modeString = prefs.getString('operationMode') ?? 'manual';
    setState(() {
      _currentMode = modeString == 'auto' ? OperationMode.auto : OperationMode.manual;
      _newMode = _currentMode;
    });
  }

  Future<void> _loadAutoModeSettings() async {
    final settings = await PosSettingsHelper.loadSettings();
    setState(() {
      _urlController.text = settings['url'] ?? '';
      _stationNameController.text = settings['stationName'] ?? '';
      _fetchingTimeController.text = settings['fetchingTime'] ?? '';
    });
  }

  bool _validateAutoModeSettings() {
    if (_newMode == OperationMode.auto) {
      if (_urlController.text.trim().isEmpty ||
          _stationNameController.text.trim().isEmpty ||
          _fetchingTimeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all auto mode settings'),
            backgroundColor: Colors.grey,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _handleModeChange() async {
    if (_currentMode == _newMode) {
      // No change, just go back
      Navigator.pop(context);
      return;
    }

    if (!_validateAutoModeSettings()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_newMode == OperationMode.auto) {
        // Switching to auto - save settings and trigger full sync
        await PosSettingsHelper.saveSettings(
          url: _urlController.text.trim(),
          stationName: _stationNameController.text.trim(),
          fetchingTime: _fetchingTimeController.text.trim(),
        );

        // Save the mode
        await SharedPrefsHelper.savePosSettings(
          mode: 'auto',
          receiptCount: 1, // Keep existing receipt count
          printPolicies: false, // Keep existing print policies
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully switched to Auto mode'),
            backgroundColor: hexToColor('8f9c68'),
            duration: Duration(seconds: 2),
          ),
        );

      } else {
        // Switching to manual - save mode and trigger re-sync
        await SharedPrefsHelper.savePosSettings(
          mode: 'manual',
          receiptCount: 1, // Keep existing receipt count  
          printPolicies: false, // Keep existing print policies
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully switched to Manual mode'),
            backgroundColor: hexToColor('8f9c68'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Wait a moment for the snackbar to show
      await Future.delayed(Duration(milliseconds: 500));

      // Navigate to UsersPage (logout) and clear the entire navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => UsersPage()),
          (route) => false, // Remove all previous routes
        );
      }

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings'),
          backgroundColor: Colors.grey,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAutoModeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text('Auto Mode Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 12),
        
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'URL',
            hintText: 'Enter API URL',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
            ),
          ),
        ),
        SizedBox(height: 12),
        
        TextField(
          controller: _stationNameController,
          decoration: InputDecoration(
            labelText: 'Station Name',
            hintText: 'Enter station name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
            ),
          ),
        ),
        SizedBox(height: 12),
        
        TextField(
          controller: _fetchingTimeController,
          decoration: InputDecoration(
            labelText: 'Fetching Time',
            hintText: 'Enter time in seconds',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('Operation Mode'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Mode: ${_currentMode == OperationMode.manual ? 'Manual' : 'Auto'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: ColorsUniversal.buttonsColor,
              ),
            ),
            SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Operation Mode', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 12),
                    
                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manual'),
                          Text(
                            'Select products manually from categories',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      value: OperationMode.manual,
                      groupValue: _newMode,
                      onChanged: (value) => setState(() => _newMode = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    
                    SizedBox(height: 12),
                    
                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto'),
                          Text(
                            'Fetch pumps/nozzles automatically for fuel dispensing',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      value: OperationMode.auto,
                      groupValue: _newMode,
                      onChanged: (value) => setState(() => _newMode = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    
                    // Show auto mode settings when auto is selected
                    if (_newMode == OperationMode.auto) _buildAutoModeSettings(),
                    
                    if (_newMode != _currentMode) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorsUniversal.fillWids,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ColorsUniversal.buttonsColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: ColorsUniversal.buttonsColor),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Changing operation mode may require syncing items for optimal performance.',
                                style: TextStyle(color: ColorsUniversal.buttonsColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 55.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsUniversal.buttonsColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _isLoading ? null : _handleModeChange,
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Saving...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(
                        _currentMode == _newMode ? 'BACK' : 'APPLY CHANGES',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _stationNameController.dispose();
    _fetchingTimeController.dispose();
    super.dispose();
  }
}
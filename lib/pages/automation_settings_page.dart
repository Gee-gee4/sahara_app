// import 'package:flutter/material.dart';
// import 'package:sahara_app/pages/auto_mode_settings.dart';
// import 'package:sahara_app/utils/colors_universal.dart';
// import 'package:sahara_app/widgets/reusable_widgets.dart';

// class AutomationSettingsPage extends StatefulWidget {
//   const AutomationSettingsPage({super.key});

//   @override
//   State<AutomationSettingsPage> createState() => _AutomationSettingsPageState();
// }

// class _AutomationSettingsPageState extends State<AutomationSettingsPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: myAppBar('Automation Settings'),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             AutoModeSettings(borderColor: ColorsUniversal.buttonsColor),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 child: Align(
//                   alignment: Alignment.bottomCenter,
//                   child: myButton(context, () {}, 'Save'),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

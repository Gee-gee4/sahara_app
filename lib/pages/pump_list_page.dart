import 'package:flutter/material.dart';

class PumpListPage extends StatelessWidget {
  final String categoryName;
  final VoidCallback onBack;

  const PumpListPage({super.key, required this.categoryName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final dummyPumps = ['Pump 1', 'Pump 2', 'Pump 3'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName - Pumps'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: ListView.builder(
        itemCount: dummyPumps.length,
        itemBuilder: (context, index) {
          final pump = dummyPumps[index];
          return ListTile(
            title: Text(pump),
            onTap: () {
              // Later you can navigate to NozzleListPage
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected $pump')),
              );
            },
          );
        },
      ),
    );
  }
}

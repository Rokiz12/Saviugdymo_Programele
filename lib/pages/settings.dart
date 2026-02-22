import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Shows on which page is selected
      appBar: AppBar(
        title: Text('Nustatymai',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),


    );
  }
}

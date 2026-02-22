import 'package:flutter/material.dart';

class MinigamesPage extends StatelessWidget {
  const MinigamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Shows on which page is selected
      appBar: AppBar(
        title: Text('Žaidimukai',
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

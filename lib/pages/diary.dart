import 'package:flutter/material.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Shows on which page is selected
      appBar: AppBar(
        title: Text('Dienoraštis',
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

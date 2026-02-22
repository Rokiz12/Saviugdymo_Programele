import 'package:flutter/material.dart';

class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Shows on which page is selected
      appBar: AppBar(
        title: Text('Avataras',
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

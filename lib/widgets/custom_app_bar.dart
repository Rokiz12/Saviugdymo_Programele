import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.yellow,
      elevation: 0,

      leading: Navigator.canPop(context)
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      )
          : null,

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),

      actions: [
        if (ModalRoute.of(context)?.settings.name != '/settings')
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
      ],

      bottom: bottom,

      bottomOpacity: 1,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 3));
}
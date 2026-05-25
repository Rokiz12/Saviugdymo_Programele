import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.background2,
      elevation: 0,

      leading: Navigator.canPop(context)
          ? IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textColor),
        onPressed: () => Navigator.pop(context),
      )
          : null,

      title: Image.asset(
        colors.logo,

        height: 32,
      ),


      actions: [
        if (ModalRoute.of(context)?.settings.name != '/settings')
          IconButton(
            icon: Icon(Icons.settings, color: colors.textColor),
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
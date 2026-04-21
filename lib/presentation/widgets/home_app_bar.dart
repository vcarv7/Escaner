import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;

  const HomeAppBar({
    super.key,
    required this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
      ),
      title: const Text('Escáner'),
      centerTitle: true,
    );
  }
}
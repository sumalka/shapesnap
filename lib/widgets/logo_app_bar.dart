import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;

  const LogoAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.pink),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 50,
            width: 50,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.star,
                color: Colors.pink,
                size: 40,
              );
            },
          ),
          const SizedBox(width: 8),
          if (title != null)
            Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2A4F),
              ),
            ),
        ],
      ),
      actions: actions,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
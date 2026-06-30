import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Muestra un SnackBar elegante y flotante en vez del rojo plano por defecto.
void showAppSnackBar(
  BuildContext context, {
  required String mensaje,
  bool esError = true,
}) {
  final color = esError ? AppColors.danger : AppColors.success;
  final icon = esError
      ? Icons.error_outline_rounded
      : Icons.check_circle_outline_rounded;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).cardTheme.color,
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      content: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

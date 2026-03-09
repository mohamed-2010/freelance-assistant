import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;
  final bool showIcon;

  const StatusChip({
    super.key,
    required this.status,
    this.onTap,
    this.showIcon = true,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.pending;
      case 'in_progress':
        return const Color(0xFF6366F1);
      case 'review':
        return const Color(0xFF8B5CF6);
      case 'done':
        return AppTheme.paid;
      case 'delivered':
        return const Color(0xFF06B6D4);
      // Legacy statuses
      case 'paid':
        return AppTheme.paid;
      case 'invoiced':
        return AppTheme.invoiced;
      // Project statuses
      case 'active':
        return AppTheme.success;
      case 'completed':
        return AppTheme.invoiced;
      case 'on-hold':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'in_progress':
        return Icons.construction_rounded;
      case 'review':
        return Icons.visibility_rounded;
      case 'done':
        return Icons.check_circle_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'paid':
        return Icons.check_circle_rounded;
      case 'invoiced':
        return Icons.receipt_long_rounded;
      case 'active':
        return Icons.play_circle_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'on-hold':
        return Icons.pause_circle_rounded;
      default:
        return Icons.circle;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'on-hold':
        return 'On Hold';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(_icon, size: 14, color: _color),
              const SizedBox(width: 4),
            ],
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

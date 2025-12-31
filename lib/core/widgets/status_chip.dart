import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

enum UserStatus {
  free,
  busy,
  studying,
  away,
}

extension UserStatusExtension on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.free:
        return 'Free';
      case UserStatus.busy:
        return 'Busy';
      case UserStatus.studying:
        return 'Studying';
      case UserStatus.away:
        return 'Away';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.free:
        return AppColors.statusFree;
      case UserStatus.busy:
        return AppColors.statusBusy;
      case UserStatus.studying:
        return AppColors.statusStudying;
      case UserStatus.away:
        return AppColors.statusAway;
    }
  }
}

class StatusChip extends StatelessWidget {
  final UserStatus status;
  final bool isSelected;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.status,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? status.color : Colors.transparent,
          border: Border.all(
            color: status.color,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : status.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

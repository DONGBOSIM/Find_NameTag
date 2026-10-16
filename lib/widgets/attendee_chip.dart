import 'package:flutter/material.dart';
import '../models/attendee.dart';

/// 참석자 상태를 직관적으로 나타내는 태그 칩 위젯
class AttendeeChip extends StatelessWidget {
  final Attendee attendee;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showDeleteButton;

  const AttendeeChip({
    super.key,
    required this.attendee,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. 상태별 색상 및 스타일 결정
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (attendee.isChecked) {
      // 체크 완료(코트 꽂음) 상태
      backgroundColor = Colors.grey.shade800;
      borderColor = Colors.grey.shade600;
      textColor = Colors.grey.shade400;
      icon = Icons.check_circle_outline;
    } else if (attendee.isMatched) {
      // 매칭판에서 발견된 상태
      backgroundColor = isSelected
          ? const Color(0xFF00E5FF).withOpacity(0.25)
          : const Color(0xFF00E5FF).withOpacity(0.12);
      borderColor = isSelected ? const Color(0xFFFF9100) : const Color(0xFF00E5FF);
      textColor = const Color(0xFF00E5FF);
      icon = Icons.location_on_outlined;
    } else {
      // 매칭판 미발견 상태
      backgroundColor = const Color(0xFFFF9100).withOpacity(0.12);
      borderColor = const Color(0xFFFF9100);
      textColor = const Color(0xFFFFB74D);
      icon = Icons.warning_amber_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 5),
              ],
              Text(
                attendee.name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  decoration:
                      attendee.isChecked ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey.shade400,
                ),
              ),
              if (attendee.similarity != null &&
                  attendee.similarity! < 0.99 &&
                  !attendee.isChecked) ...[
                const SizedBox(width: 4),
                Text(
                  '${(attendee.similarity! * 100).toInt()}%',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
              if (showDeleteButton && onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

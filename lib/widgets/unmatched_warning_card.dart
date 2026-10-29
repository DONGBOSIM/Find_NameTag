import 'package:flutter/material.dart';
import '../models/attendee.dart';
import '../theme/app_theme.dart';

/// 매칭판에서 감지되지 않은 참석자들을 안내하는 경고 카드 위젯
class UnmatchedWarningCard extends StatelessWidget {
  final List<Attendee> unmatchedAttendees;
  final VoidCallback? onRetryScan;

  const UnmatchedWarningCard({
    super.key,
    required this.unmatchedAttendees,
    this.onRetryScan,
  });

  @override
  Widget build(BuildContext context) {
    if (unmatchedAttendees.isEmpty) {
      return const SizedBox.shrink();
    }

    final warningColor = context.warningAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF2A1F0D)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0xFFFF9100)
              : const Color(0xFFFFB74D),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '매칭판 미발견 인원 (${unmatchedAttendees.length}명)',
                style: TextStyle(
                  color: warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (onRetryScan != null)
                TextButton.icon(
                  onPressed: onRetryScan,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.refresh, size: 14, color: warningColor),
                  label: Text(
                    '재촬영',
                    style: TextStyle(color: warningColor, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '빛 반사, 각도 또는 보드판에 명찰이 없는 경우일 수 있습니다. 명찰 상태를 확인해 주세요.',
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: unmatchedAttendees.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF3E2C14)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: warningColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  a.name,
                  style: TextStyle(
                    color: warningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

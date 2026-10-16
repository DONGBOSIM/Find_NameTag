import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/name_card_match.dart';

/// 촬영된 매칭판 원본 이미지의 비율에 맞춰
/// 각 네임카드의 위치에 형광 테두리 및 참석자 이름을 오버레이 렌더링하는 CustomPainter
class BoundingBoxPainter extends CustomPainter {
  /// 매칭된 명찰 리스트
  final List<NameCardMatch> matches;

  /// 원본 이미지 크기
  final Size imageSize;

  /// 현재 선택/강조된 네임카드 ID
  final String? selectedMatchId;

  BoundingBoxPainter({
    required this.matches,
    required this.imageSize,
    this.selectedMatchId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    // 원본 이미지 좌표 -> 현재 렌더링 캔버스 좌표 변환 비율
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    for (final match in matches) {
      final isSelected = match.id == selectedMatchId;
      final isChecked = match.isChecked;

      // 캔버스 크기에 맞춘 scaledRect 계산
      final Rect scaledRect = Rect.fromLTWH(
        match.boundingBox.left * scaleX,
        match.boundingBox.top * scaleY,
        match.boundingBox.width * scaleX,
        match.boundingBox.height * scaleY,
      );

      if (isChecked) {
        _paintCheckedBox(canvas, scaledRect, match);
      } else {
        _paintActiveBox(canvas, scaledRect, match, isSelected);
      }
    }
  }

  /// 활성(미체크) 상태 네임카드: 선명한 형광 네온 테두리 및 뱃지
  void _paintActiveBox(
    Canvas canvas,
    Rect rect,
    NameCardMatch match,
    bool isSelected,
  ) {
    // 1. 네온 하이라이트 색상 (선택 시 오렌지 네온, 기본은 민트/라임 네온)
    final Color strokeColor =
        isSelected ? const Color(0xFFFF9100) : const Color(0xFF00E5FF);
    final Color fillColor =
        isSelected ? const Color(0x33FF9100) : const Color(0x2200E5FF);

    // 내부 반투명 채우기
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      fillPaint,
    );

    // 형광 외곽선
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.5 : 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      strokePaint,
    );

    // 모서리 펄스 효과 (시각적 고급스러움)
    final glowPaint = Paint()
      ..color = strokeColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 6.0 : 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      glowPaint,
    );

    // 2. 상단 이름 라벨 배지 렌더링
    _paintNameBadge(
      canvas: canvas,
      rect: rect,
      title: match.attendeeName,
      subtitle: match.similarity < 0.99
          ? '${(match.similarity * 100).toInt()}%'
          : null,
      bgColor: strokeColor,
      textColor: Colors.black,
    );
  }

  /// 체크 완료된 상태: 회색 반투명 오버레이 및 체크마크
  void _paintCheckedBox(Canvas canvas, Rect rect, NameCardMatch match) {
    // 회색 반투명 채우기
    final fillPaint = Paint()
      ..color = const Color(0xAA424242)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      fillPaint,
    );

    // 점선 테두리 대용 회색 선
    final strokePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      strokePaint,
    );

    // 체크 완료 라벨 배지
    _paintNameBadge(
      canvas: canvas,
      rect: rect,
      title: '✓ ${match.attendeeName}',
      subtitle: '완료',
      bgColor: const Color(0xFF616161),
      textColor: Colors.white,
    );
  }

  /// 바운딩 박스 위/안에 참석자 이름 및 유사도 pill 배지 렌더링
  void _paintNameBadge({
    required Canvas canvas,
    required Rect rect,
    required String title,
    String? subtitle,
    required Color bgColor,
    required Color textColor,
  }) {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: title,
          style: TextStyle(
            color: textColor,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const TextSpan(text: ' '),
          TextSpan(
            text: subtitle,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const double paddingH = 6.0;
    const double paddingV = 2.0;
    final double badgeWidth = textPainter.width + paddingH * 2;
    final double badgeHeight = textPainter.height + paddingV * 2;

    // 배지 위치: 박스 상단 위에 올리되, 화면 위로 벗어나면 박스 내부 상단에 배치
    double badgeLeft = rect.left;
    double badgeTop = rect.top - badgeHeight - 4;
    if (badgeTop < 0) {
      badgeTop = rect.top + 2;
    }

    final badgeRect = Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight);

    final badgeBgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      badgeBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(badgeLeft + paddingH, badgeTop + paddingV),
    );
  }

  /// 캔버스 상의 터치 좌표가 어떤 네임카드 영역에 속하는지 판정하는 히트테스트 헬퍼
  static NameCardMatch? findHitMatch({
    required Offset localPosition,
    required Size canvasSize,
    required Size imageSize,
    required List<NameCardMatch> matches,
  }) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return null;

    final double scaleX = canvasSize.width / imageSize.width;
    final double scaleY = canvasSize.height / imageSize.height;

    // 터치 편의성을 위해 클릭 감지 영역을 살짝 확장 (여유 마진 8px)
    for (final match in matches.reversed) {
      final Rect scaledRect = Rect.fromLTWH(
        match.boundingBox.left * scaleX,
        match.boundingBox.top * scaleY,
        match.boundingBox.width * scaleX,
        match.boundingBox.height * scaleY,
      ).inflate(8.0);

      if (scaledRect.contains(localPosition)) {
        return match;
      }
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.matches != matches ||
        oldDelegate.selectedMatchId != selectedMatchId ||
        oldDelegate.imageSize != imageSize;
  }
}

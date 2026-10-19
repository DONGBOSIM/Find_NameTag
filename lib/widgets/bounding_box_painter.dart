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

  /// 매칭률(%) 표시 여부 (기본값: false - 위치 색상 우선 표시)
  final bool showSimilarity;

  BoundingBoxPainter({
    required this.matches,
    required this.imageSize,
    this.selectedMatchId,
    this.showSimilarity = false,
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

  /// 활성(미체크) 상태 네임카드: 네임태그 영역 바로 위에 이름을 덮어써서 렌더링
  void _paintActiveBox(
    Canvas canvas,
    Rect rect,
    NameCardMatch match,
    bool isSelected,
  ) {
    // 선택 시 오렌지, 기본은 선명한 민트/형광 시안
    final Color bgColor =
        isSelected ? const Color(0xFFFF9100) : const Color(0xFF00E5FF);
    final Color borderColor =
        isSelected ? const Color(0xFFFFD54F) : const Color(0xFF00B0FF);

    _paintDirectNameOverlay(
      canvas: canvas,
      rect: rect,
      title: match.attendeeName,
      subtitle: (showSimilarity && match.similarity < 0.99)
          ? '${(match.similarity * 100).toInt()}%'
          : null,
      bgColor: bgColor,
      borderColor: borderColor,
      textColor: Colors.black,
      isSelected: isSelected,
    );
  }

  /// 체크 완료된 상태: 차분한 회색 오버레이 및 체크마크
  void _paintCheckedBox(Canvas canvas, Rect rect, NameCardMatch match) {
    _paintDirectNameOverlay(
      canvas: canvas,
      rect: rect,
      title: '✓ ${match.attendeeName}',
      subtitle: showSimilarity ? '완료' : null,
      bgColor: const Color(0xFF455A64),
      borderColor: const Color(0xFF78909C),
      textColor: Colors.white,
      isSelected: false,
    );
  }

  /// 네임카드 영역(rect) 바로 위에 배경과 이름을 직접 덮어쓰는 렌더러
  void _paintDirectNameOverlay({
    required Canvas canvas,
    required Rect rect,
    required String title,
    String? subtitle,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required bool isSelected,
  }) {
    // 기존 네임태그 인쇄 글자를 완전히 덮을 수 있도록 미세 여백 확장 (+2px)
    final Rect overlayRect = rect.inflate(2.0);
    final rrect = RRect.fromRectAndRadius(overlayRect, const Radius.circular(4.0));

    // 1. 네임태그 위 덮어쓰기 배경 (불투명도 0.96으로 기존 인쇄 글자를 깔끔하게 가림)
    final bgPaint = Paint()
      ..color = bgColor.withOpacity(0.96)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // 2. 외곽선 테두리
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // 3. 텍스트 레이아웃 계산 (높이에 맞춰 폰트 크기 동적 조절)
    double fontSize = (overlayRect.height * 0.65).clamp(11.0, 16.0);

    TextPainter textPainter = _createTextPainter(
      title: title,
      subtitle: subtitle,
      textColor: textColor,
      fontSize: fontSize,
    );

    // 네임카드 너비를 초과하면 폰트 크기를 자동 축소하여 한 줄에 맞춤
    if (textPainter.width > overlayRect.width - 4.0 && fontSize > 9.0) {
      fontSize = (fontSize * ((overlayRect.width - 4.0) / textPainter.width)).clamp(9.0, fontSize);
      textPainter = _createTextPainter(
        title: title,
        subtitle: subtitle,
        textColor: textColor,
        fontSize: fontSize,
      );
    }

    // 4. 네임카드 정중앙에 텍스트 페인팅 (이웃 명찰을 전혀 침범하지 않음)
    final double textX = overlayRect.left + (overlayRect.width - textPainter.width) / 2;
    final double textY = overlayRect.top + (overlayRect.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  TextPainter _createTextPainter({
    required String title,
    String? subtitle,
    required Color textColor,
    required double fontSize,
  }) {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: title,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const TextSpan(text: ' '),
          TextSpan(
            text: subtitle,
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontSize: (fontSize * 0.78).clamp(8.5, 12.0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    return TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
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
        oldDelegate.imageSize != imageSize ||
        oldDelegate.showSimilarity != showSimilarity;
  }
}

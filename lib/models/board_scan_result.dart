import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'attendee.dart';
import 'name_card_match.dart';

/// ML Kit OCR로 보드판에서 감지된 가공되지 않은 텍스트 요소
@immutable
class RawOcrDetection {
  final String text;
  final Rect boundingBox;
  final double? confidence;

  const RawOcrDetection({
    required this.text,
    required this.boundingBox,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'boundingBox': {
      'left': boundingBox.left,
      'top': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
    },
    'confidence': confidence,
  };

  factory RawOcrDetection.fromJson(Map<String, dynamic> json) {
    final bb = json['boundingBox'] as Map<String, dynamic>;
    return RawOcrDetection(
      text: json['text'] as String,
      boundingBox: Rect.fromLTWH(
        (bb['left'] as num).toDouble(),
        (bb['top'] as num).toDouble(),
        (bb['width'] as num).toDouble(),
        (bb['height'] as num).toDouble(),
      ),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

/// 매칭판 스캔 및 참석자 매칭 종합 결과 모델
@immutable
class BoardScanResult {
  /// 촬영/선택된 매칭판 원본 이미지의 로컬 파일 경로
  final String imagePath;

  /// 원본 이미지 가로 해상도 (픽셀)
  final double imageWidth;

  /// 원본 이미지 세로 해상도 (픽셀)
  final double imageHeight;

  /// 매칭 성공된 네임카드 목록
  final List<NameCardMatch> matches;

  /// 매칭판에서 찾지 못한 미발견 참석자 목록
  final List<Attendee> unmatchedAttendees;

  /// 참석자와 매칭되지 않은 매칭판의 기타 텍스트 블록 목록
  final List<RawOcrDetection> otherDetections;

  /// 스캔 완료 시각
  final DateTime scannedAt;

  const BoardScanResult({
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.matches,
    required this.unmatchedAttendees,
    this.otherDetections = const [],
    required this.scannedAt,
  });

  /// 매칭 성공한 인원 수
  int get matchCount => matches.length;

  /// 미발견 인원 수
  int get unmatchedCount => unmatchedAttendees.length;

  /// 전체 참석자 수
  int get totalAttendeeCount => matchCount + unmatchedCount;

  /// 코트 배치 완료(체크)된 명찰 수
  int get checkedCount => matches.where((m) => m.isChecked).length;

  /// 모든 매칭 인원의 코트 배치가 완료되었는지 여부
  bool get isAllChecked => matches.isNotEmpty && matches.every((m) => m.isChecked);

  /// 이미지의 가로/세로 비율 (InteractiveViewer 및 캔버스 렌더링에 사용)
  double get imageAspectRatio => imageWidth == 0 || imageHeight == 0 ? 1.0 : imageWidth / imageHeight;

  /// 특정 ID의 매칭 아이템 체크 상태를 토글한 새 결과 반환
  BoardScanResult toggleMatchCheck(String matchId) {
    final updatedMatches = matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(isChecked: !m.isChecked);
      }
      return m;
    }).toList();

    return copyWith(matches: updatedMatches);
  }

  /// 특정 참석자 ID와 매칭된 명찰의 체크 상태를 토글한 새 결과 반환
  BoardScanResult toggleAttendeeCheck(String attendeeId) {
    final updatedMatches = matches.map((m) {
      if (m.attendeeId == attendeeId) {
        return m.copyWith(isChecked: !m.isChecked);
      }
      return m;
    }).toList();

    return copyWith(matches: updatedMatches);
  }

  BoardScanResult copyWith({
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
    List<NameCardMatch>? matches,
    List<Attendee>? unmatchedAttendees,
    List<RawOcrDetection>? otherDetections,
    DateTime? scannedAt,
  }) {
    return BoardScanResult(
      imagePath: imagePath ?? this.imagePath,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      matches: matches ?? this.matches,
      unmatchedAttendees: unmatchedAttendees ?? this.unmatchedAttendees,
      otherDetections: otherDetections ?? this.otherDetections,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'matches': matches.map((m) => m.toJson()).toList(),
      'unmatchedAttendees': unmatchedAttendees.map((a) => a.toJson()).toList(),
      'otherDetections': otherDetections.map((d) => d.toJson()).toList(),
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory BoardScanResult.fromJson(Map<String, dynamic> json) {
    return BoardScanResult(
      imagePath: json['imagePath'] as String,
      imageWidth: (json['imageWidth'] as num).toDouble(),
      imageHeight: (json['imageHeight'] as num).toDouble(),
      matches: (json['matches'] as List<dynamic>)
          .map((item) => NameCardMatch.fromJson(item as Map<String, dynamic>))
          .toList(),
      unmatchedAttendees: (json['unmatchedAttendees'] as List<dynamic>)
          .map((item) => Attendee.fromJson(item as Map<String, dynamic>))
          .toList(),
      otherDetections: (json['otherDetections'] as List<dynamic>? ?? [])
          .map((item) => RawOcrDetection.fromJson(item as Map<String, dynamic>))
          .toList(),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}

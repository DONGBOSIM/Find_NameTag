import 'dart:ui';
import 'package:flutter/foundation.dart';

/// 체육관 매칭판에서 감지 및 매칭된 네임카드 위치 정보 모델
@immutable
class NameCardMatch {
  /// 매칭 고유 ID
  final String id;

  /// 연결된 참석자 ID
  final String? attendeeId;

  /// 매칭된 참석자 이름
  final String attendeeName;

  /// ML Kit Text Recognizer가 실제로 인식한 보드판 텍스트 (예: '심둥보')
  final String detectedText;

  /// 한글 자모 분리 퍼지 유사도 (0.0 ~ 1.0, 75% 이상 매칭)
  final double similarity;

  /// 매칭판 원본 이미지 상의 절대 픽셀 바운딩 박스 좌표
  final Rect boundingBox;

  /// 0.0 ~ 1.0 비율로 정규화된 바운딩 박스 (화면 해상도/배율 변경 시 활용)
  final Rect normalizedRect;

  /// 보드판에서 명찰을 꺼내 코트에 꽂았는지 여부
  final bool isChecked;

  /// 디버깅 및 분석용 자모 분해 문자열
  final String? attendeeJamo;
  final String? detectedJamo;

  const NameCardMatch({
    required this.id,
    this.attendeeId,
    required this.attendeeName,
    required this.detectedText,
    required this.similarity,
    required this.boundingBox,
    required this.normalizedRect,
    this.isChecked = false,
    this.attendeeJamo,
    this.detectedJamo,
  });

  /// 바운딩 박스 중심점 (터치 영역 검사 및 줌인 등에 활용)
  Offset get center => boundingBox.center;

  /// 바운딩 박스 가로/세로 비율
  double get aspectRatio => boundingBox.width / (boundingBox.height == 0 ? 1 : boundingBox.height);

  NameCardMatch copyWith({
    String? id,
    String? attendeeId,
    String? attendeeName,
    String? detectedText,
    double? similarity,
    Rect? boundingBox,
    Rect? normalizedRect,
    bool? isChecked,
    String? attendeeJamo,
    String? detectedJamo,
  }) {
    return NameCardMatch(
      id: id ?? this.id,
      attendeeId: attendeeId ?? this.attendeeId,
      attendeeName: attendeeName ?? this.attendeeName,
      detectedText: detectedText ?? this.detectedText,
      similarity: similarity ?? this.similarity,
      boundingBox: boundingBox ?? this.boundingBox,
      normalizedRect: normalizedRect ?? this.normalizedRect,
      isChecked: isChecked ?? this.isChecked,
      attendeeJamo: attendeeJamo ?? this.attendeeJamo,
      detectedJamo: detectedJamo ?? this.detectedJamo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendeeId': attendeeId,
      'attendeeName': attendeeName,
      'detectedText': detectedText,
      'similarity': similarity,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'normalizedRect': {
        'left': normalizedRect.left,
        'top': normalizedRect.top,
        'width': normalizedRect.width,
        'height': normalizedRect.height,
      },
      'isChecked': isChecked,
      'attendeeJamo': attendeeJamo,
      'detectedJamo': detectedJamo,
    };
  }

  factory NameCardMatch.fromJson(Map<String, dynamic> json) {
    final bb = json['boundingBox'] as Map<String, dynamic>;
    final nb = json['normalizedRect'] as Map<String, dynamic>;
    return NameCardMatch(
      id: json['id'] as String,
      attendeeId: json['attendeeId'] as String?,
      attendeeName: json['attendeeName'] as String,
      detectedText: json['detectedText'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      boundingBox: Rect.fromLTWH(
        (bb['left'] as num).toDouble(),
        (bb['top'] as num).toDouble(),
        (bb['width'] as num).toDouble(),
        (bb['height'] as num).toDouble(),
      ),
      normalizedRect: Rect.fromLTWH(
        (nb['left'] as num).toDouble(),
        (nb['top'] as num).toDouble(),
        (nb['width'] as num).toDouble(),
        (nb['height'] as num).toDouble(),
      ),
      isChecked: json['isChecked'] as bool? ?? false,
      attendeeJamo: json['attendeeJamo'] as String?,
      detectedJamo: json['detectedJamo'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NameCardMatch &&
        other.id == id &&
        other.attendeeId == attendeeId &&
        other.attendeeName == attendeeName &&
        other.detectedText == detectedText &&
        other.similarity == similarity &&
        other.boundingBox == boundingBox &&
        other.isChecked == isChecked;
  }

  @override
  int get hashCode => Object.hash(id, attendeeId, attendeeName, detectedText, similarity, boundingBox, isChecked);

  @override
  String toString() {
    return 'NameCardMatch(name: $attendeeName, detected: $detectedText, sim: ${(similarity * 100).toStringAsFixed(1)}%, box: $boundingBox, checked: $isChecked)';
  }
}

import 'package:flutter/foundation.dart';

/// 동호회 참석 명단에서 추출된 참석자 모델
@immutable
class Attendee {
  /// 참석자 고유 ID
  final String id;

  /// 정제된 한글 참석자 이름 (2~4글자)
  final String name;

  /// 캡처본 OCR에서 추출되었던 원본 텍스트 (예: '1. 홍길동 (참석)')
  final String? originalRawText;

  /// 매칭판에서 네임카드를 찾았는지 여부
  final bool isMatched;

  /// 사용자가 보드판에서 명찰을 꺼내 코트에 꽂았음을 나타내는 체크 상태
  final bool isChecked;

  /// 매칭판에서 발견된 [NameCardMatch]의 고유 ID
  final String? matchedNameCardId;

  /// 매칭 유사도 (0.0 ~ 1.0)
  final double? similarity;

  const Attendee({
    required this.id,
    required this.name,
    this.originalRawText,
    this.isMatched = false,
    this.isChecked = false,
    this.matchedNameCardId,
    this.similarity,
  });

  /// 상태 업데이트를 위한 copyWith
  Attendee copyWith({
    String? id,
    String? name,
    String? originalRawText,
    bool? isMatched,
    bool? isChecked,
    String? matchedNameCardId,
    double? similarity,
  }) {
    return Attendee(
      id: id ?? this.id,
      name: name ?? this.name,
      originalRawText: originalRawText ?? this.originalRawText,
      isMatched: isMatched ?? this.isMatched,
      isChecked: isChecked ?? this.isChecked,
      matchedNameCardId: matchedNameCardId ?? this.matchedNameCardId,
      similarity: similarity ?? this.similarity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalRawText': originalRawText,
      'isMatched': isMatched,
      'isChecked': isChecked,
      'matchedNameCardId': matchedNameCardId,
      'similarity': similarity,
    };
  }

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      id: json['id'] as String,
      name: json['name'] as String,
      originalRawText: json['originalRawText'] as String?,
      isMatched: json['isMatched'] as bool? ?? false,
      isChecked: json['isChecked'] as bool? ?? false,
      matchedNameCardId: json['matchedNameCardId'] as String?,
      similarity: (json['similarity'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendee &&
        other.id == id &&
        other.name == name &&
        other.isMatched == isMatched &&
        other.isChecked == isChecked &&
        other.matchedNameCardId == matchedNameCardId;
  }

  @override
  int get hashCode => Object.hash(id, name, isMatched, isChecked, matchedNameCardId);

  @override
  String toString() {
    return 'Attendee(id: $id, name: $name, isMatched: $isMatched, isChecked: $isChecked, similarity: $similarity)';
  }
}

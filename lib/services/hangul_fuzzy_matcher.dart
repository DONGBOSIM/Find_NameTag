import 'dart:math' as math;

/// 한글 자모 분리 결과 클래스
class DecomposedHangul {
  final String cho;
  final String jung;
  final String jong;

  const DecomposedHangul({
    required this.cho,
    required this.jung,
    required this.jong,
  });

  /// 종성이 비어있지 않으면 초+중+종, 비어있으면 초+중
  String get combined => '$cho$jung$jong';

  @override
  String toString() => combined;
}

/// 한글 퍼지 매칭 세부 결과
class FuzzyMatchResult {
  /// 매칭 성공 여부 (similarity >= threshold)
  final bool isMatched;

  /// 계산된 유사도 점수 (0.0 ~ 1.0)
  final double similarity;

  /// 자모 간의 Levenshtein 거리
  final int distance;

  /// 참석자 이름의 자모 분해 결과
  final String attendeeJamo;

  /// 비교 대상(감지된 텍스트)의 자모 분해 결과
  final String detectedJamo;

  /// 슬라이딩 윈도우 매칭 시 가장 일치율이 높았던 부분 문자열
  final String matchedSubstring;

  const FuzzyMatchResult({
    required this.isMatched,
    required this.similarity,
    required this.distance,
    required this.attendeeJamo,
    required this.detectedJamo,
    required this.matchedSubstring,
  });

  @override
  String toString() {
    return 'FuzzyMatchResult(matched: $isMatched, sim: ${(similarity * 100).toStringAsFixed(1)}%, dist: $distance, text: "$matchedSubstring")';
  }
}

/// 조명 반사, 비닐 코팅, 각도 등으로 인한 OCR 오인식을 극복하기 위한
/// 한글 초/중/종성 분리 및 Levenshtein / Jaro-Winkler 퍼지 매칭 엔진
class HangulFuzzyMatcher {
  // 한글 유니코드 상수
  static const int _hangulBase = 0xAC00; // '가'
  static const int _hangulEnd = 0xD7A3; // '힣'

  // 초성 19자
  static const List<String> choTable = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
    'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  // 중성 21자
  static const List<String> jungTable = [
    'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ',
    'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ',
    'ㅡ', 'ㅢ', 'ㅣ',
  ];

  // 종성 28자 (인덱스 0은 종성 없음)
  static const List<String> jongTable = [
    '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ',
    'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ',
    'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  /// 기본 유사도 임계값 (75%)
  static const double defaultThreshold = 0.75;

  /// 문자가 완성형 한글 음절('가'~'힣')인지 확인
  static bool isHangulSyllable(String char) {
    if (char.isEmpty) return false;
    final int code = char.codeUnitAt(0);
    return code >= _hangulBase && code <= _hangulEnd;
  }

  /// 단일 한글 음절을 초성, 중성, 종성으로 분해
  static DecomposedHangul decomposeChar(String char) {
    if (!isHangulSyllable(char)) {
      return DecomposedHangul(cho: char, jung: '', jong: '');
    }

    final int code = char.codeUnitAt(0) - _hangulBase;
    final int jongIndex = code % 28;
    final int jungIndex = ((code - jongIndex) ~/ 28) % 21;
    final int choIndex = ((code - jongIndex) ~/ 28) ~/ 21;

    return DecomposedHangul(
      cho: choTable[choIndex],
      jung: jungTable[jungIndex],
      jong: jongTable[jongIndex],
    );
  }

  /// 문자열 전체를 자모 시퀀스로 분해
  /// 예: "심동보" -> "ㅅㅣㅁㄷㅗㅇㅂㅗ"
  /// [removeWhitespace] true일 경우 공백 및 특수문자 제거
  static String decompose(String input, {bool removeWhitespace = true}) {
    final StringBuffer sb = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final String char = input[i];
      if (isHangulSyllable(char)) {
        final decomposed = decomposeChar(char);
        sb.write(decomposed.cho);
        sb.write(decomposed.jung);
        if (decomposed.jong.isNotEmpty) {
          sb.write(decomposed.jong);
        }
      } else {
        if (removeWhitespace && (char.trim().isEmpty || _isNoiseChar(char))) {
          continue;
        }
        sb.write(char);
      }
    }

    return sb.toString();
  }

  /// 노이즈 문자(OCR에서 자주 튀는 특수문자나 괄호 등) 판정
  static bool _isNoiseChar(String char) {
    const noise = r'''!@#$%^&*()-_=+[{]}\|;:'",<.>/?`~·•■□▲▶★☆1234567890''';
    return noise.contains(char);
  }

  /// 두 문자열 사이의 Levenshtein Distance (편집 거리) 계산
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1, // 삽입
          math.min(
            v0[j + 1] + 1, // 삭제
            v0[j] + cost, // 교체
          ),
        );
      }

      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// 자모 분리 후 Levenshtein Distance 기반 유사도 계산 (0.0 ~ 1.0)
  /// 유사도 공식 = 1.0 - (거리 / max(길이1, 길이2))
  static double calculateSimilarity(String s1, String s2) {
    final String jamo1 = decompose(s1);
    final String jamo2 = decompose(s2);

    if (jamo1.isEmpty && jamo2.isEmpty) return 1.0;
    if (jamo1.isEmpty || jamo2.isEmpty) return 0.0;
    if (jamo1 == jamo2) return 1.0;

    final int distance = levenshteinDistance(jamo1, jamo2);
    final int maxLength = math.max(jamo1.length, jamo2.length);

    if (maxLength == 0) return 1.0;
    final double similarity = 1.0 - (distance / maxLength);
    return math.max(0.0, similarity);
  }

  /// Jaro-Winkler 유사도 계산 (접두사 일치 보너스 포함, 0.0 ~ 1.0)
  static double jaroWinklerSimilarity(String s1, String s2, {double prefixWeight = 0.1}) {
    final String j1 = decompose(s1);
    final String j2 = decompose(s2);

    if (j1 == j2) return 1.0;
    if (j1.isEmpty || j2.isEmpty) return 0.0;

    final int matchWindow = (math.max(j1.length, j2.length) ~/ 2) - 1;
    final List<bool> j1Matches = List<bool>.filled(j1.length, false);
    final List<bool> j2Matches = List<bool>.filled(j2.length, false);

    int matches = 0;
    for (int i = 0; i < j1.length; i++) {
      final int start = math.max(0, i - matchWindow);
      final int end = math.min(i + matchWindow + 1, j2.length);

      for (int k = start; k < end; k++) {
        if (!j2Matches[k] && j1[i] == j2[k]) {
          j1Matches[i] = true;
          j2Matches[k] = true;
          matches++;
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    // Transpositions
    int transpositions = 0;
    int k = 0;
    for (int i = 0; i < j1.length; i++) {
      if (!j1Matches[i]) continue;
      while (!j2Matches[k]) {
        k++;
      }
      if (j1[i] != j2[k]) transpositions++;
      k++;
    }

    final double m = matches.toDouble();
    final double jaro = (m / j1.length + m / j2.length + (m - (transpositions / 2.0)) / m) / 3.0;

    // Jaro-Winkler prefix bonus (up to 4 chars)
    int prefix = 0;
    for (int i = 0; i < math.min(4, math.min(j1.length, j2.length)); i++) {
      if (j1[i] == j2[i]) {
        prefix++;
      } else {
        break;
      }
    }

    return jaro + (prefix * prefixWeight * (1.0 - jaro));
  }

  /// 참석자 이름과 OCR 감지 텍스트 간의 퍼지 매칭 검사
  /// OCR 블록에 "A조 심둥보" 처럼 여분 단어가 포함되어 있을 경우를 대비하여
  /// 슬라이딩 윈도우 방식으로 최적 매칭 부분을 탐색
  static FuzzyMatchResult match(
    String attendeeName,
    String detectedText, {
    double threshold = defaultThreshold,
  }) {
    final String cleanAttendee = attendeeName.replaceAll(RegExp(r'\s+'), '');
    final String cleanDetected = detectedText.replaceAll(RegExp(r'\s+'), '');

    // 1. 단순 직접 비교
    final String attendeeJamo = decompose(cleanAttendee);
    final String directDetectedJamo = decompose(cleanDetected);
    final int directDist = levenshteinDistance(attendeeJamo, directDetectedJamo);
    final int maxLen = math.max(attendeeJamo.length, directDetectedJamo.length);
    final double directSim = maxLen == 0 ? 1.0 : (1.0 - (directDist / maxLen));

    if (directSim >= threshold) {
      return FuzzyMatchResult(
        isMatched: true,
        similarity: directSim,
        distance: directDist,
        attendeeJamo: attendeeJamo,
        detectedJamo: directDetectedJamo,
        matchedSubstring: cleanDetected,
      );
    }

    // 2. OCR 블록이 참석자 이름보다 길 경우, 슬라이딩 윈도우 검색
    // 예: 감지="1코트심둥보님", 참석자="심동보" (길이 3) -> "1코트", "코트심", "트심둥", "심둥보", "둥보님"
    final int targetCharCount = cleanAttendee.length;
    double bestSim = directSim;
    int bestDist = directDist;
    String bestDetectedJamo = directDetectedJamo;
    String bestSub = cleanDetected;

    // 슬라이딩 윈도우 길이: 참석자 이름 길이의 -1 ~ +1 글자 범위
    final int minWindow = math.max(2, targetCharCount - 1);
    final int maxWindow = math.min(cleanDetected.length, targetCharCount + 1);

    for (int w = minWindow; w <= maxWindow; w++) {
      for (int i = 0; i <= cleanDetected.length - w; i++) {
        final String sub = cleanDetected.substring(i, i + w);
        final String subJamo = decompose(sub);
        final int dist = levenshteinDistance(attendeeJamo, subJamo);
        final int mLen = math.max(attendeeJamo.length, subJamo.length);
        final double sim = mLen == 0 ? 1.0 : (1.0 - (dist / mLen));

        if (sim > bestSim) {
          bestSim = sim;
          bestDist = dist;
          bestDetectedJamo = subJamo;
          bestSub = sub;
        }
      }
    }

    return FuzzyMatchResult(
      isMatched: bestSim >= threshold,
      similarity: bestSim,
      distance: bestDist,
      attendeeJamo: attendeeJamo,
      detectedJamo: bestDetectedJamo,
      matchedSubstring: bestSub,
    );
  }

  /// 간이 매칭 판정 헬퍼
  static bool isMatch(
    String attendeeName,
    String detectedText, {
    double threshold = defaultThreshold,
  }) {
    return match(attendeeName, detectedText, threshold: threshold).isMatched;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:find_nametag/services/hangul_fuzzy_matcher.dart';

void main() {
  group('HangulFuzzyMatcher - 한글 자모 분리 테스트', () {
    test('완성형 한글 음절 초성/중성/종성 정확한 분리', () {
      final sim = HangulFuzzyMatcher.decomposeChar('심');
      expect(sim.cho, 'ㅅ');
      expect(sim.jung, 'ㅣ');
      expect(sim.jong, 'ㅁ');
      expect(sim.combined, 'ㅅㅣㅁ');

      final dong = HangulFuzzyMatcher.decomposeChar('동');
      expect(dong.cho, 'ㄷ');
      expect(dong.jung, 'ㅗ');
      expect(dong.jong, 'ㅇ');
      expect(dong.combined, 'ㄷㅗㅇ');

      final bo = HangulFuzzyMatcher.decomposeChar('보');
      expect(bo.cho, 'ㅂ');
      expect(bo.jung, 'ㅗ');
      expect(bo.jong, '');
      expect(bo.combined, 'ㅂㅗ');
    });

    test('단어 전체 자모 분해', () {
      expect(HangulFuzzyMatcher.decompose('심동보'), 'ㅅㅣㅁㄷㅗㅇㅂㅗ');
      expect(HangulFuzzyMatcher.decompose('심둥보'), 'ㅅㅣㅁㄷㅜㅇㅂㅗ');
      expect(HangulFuzzyMatcher.decompose('홍길동'), 'ㅎㅗㅇㄱㅣㄹㄷㅗㅇ');
    });
  });

  group('HangulFuzzyMatcher - 유사도 계산 및 퍼지 매칭 테스트', () {
    test('조명 반사 오인식 ("심동보" vs "심둥보") 매칭 성공 (87.5% >= 75%)', () {
      final result = HangulFuzzyMatcher.match('심동보', '심둥보');
      expect(result.isMatched, isTrue);
      expect(result.distance, 1);
      expect(result.similarity, closeTo(0.875, 0.001));
    });

    test('동일한 이름 매칭 (100%)', () {
      final result = HangulFuzzyMatcher.match('심동보', '심동보');
      expect(result.isMatched, isTrue);
      expect(result.distance, 0);
      expect(result.similarity, 1.0);
    });

    test('전혀 다른 이름은 매칭 실패 (임계값 75% 미만)', () {
      final result = HangulFuzzyMatcher.match('심동보', '이순신');
      expect(result.isMatched, isFalse);
      expect(result.similarity, lessThan(0.5));
    });

    test('OCR 노이즈 및 접두/접미어가 포함된 블록 슬라이딩 윈도우 매칭', () {
      // 보드판에 "[A조] 심둥보" 또는 "1등 심둥보" 형태로 인식되었을 때
      final result = HangulFuzzyMatcher.match('심동보', '[A조] 심둥보');
      expect(result.isMatched, isTrue);
      expect(result.matchedSubstring, contains('심둥보'));
      expect(result.similarity, greaterThanOrEqualTo(0.75));
    });

    test('Jaro-Winkler 유사도 측정 검증', () {
      final jwSim = HangulFuzzyMatcher.jaroWinklerSimilarity('심동보', '심둥보');
      expect(jwSim, greaterThan(0.85));
    });
  });
}

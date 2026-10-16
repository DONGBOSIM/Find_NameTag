import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/attendee.dart';

/// 동호회 참석 명단 캡처본(카카오톡, 밴드, 소모임 투표 등)에서
/// 2~4글자 유효 한글 참석자 이름을 추출하고 필터링하는 서비스
class AttendeeParserService {
  final TextRecognizer _recognizer;
  final Uuid _uuid = const Uuid();

  AttendeeParserService({TextRecognizer? recognizer})
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.korean);

  /// 참석자 명단에서 제외해야 할 동호회/투표 관련 블랙리스트 키워드
  static const Set<String> defaultBlacklist = {
    '투표', '참석', '마감', '취소', '불참', '정회원', '게스트',
    '총무', '모임장', '인원', '요일', '배드민턴', '클럽', '회비',
    '운동', '벙개', '월', '화', '수', '목', '금', '토', '일',
    '오전', '오후', '시간', '시작', '종료', '마감됨', '투표자',
    '선택', '명단', '현황', '코트', '체육관', '준비', '완료',
    '참여', '멤버', '등록', '공지', '확인', '미정', '대기',
    '댓글', '사진', '동호회', '경기', '복식', '단식', '매칭',
  };

  /// 2~4글자 순수 한글 이름 정규식
  static final RegExp _pureKoreanNameRegex = RegExp(r'^[가-힣]{2,4}$');

  /// 투표 라인에서 번호, 괄호 등 수식어를 제거하고 순수 이름을 추출하기 위한 패턴
  /// 예: "1. 홍길동 (참석)" -> "홍길동"
  /// 예: "3) 김철수(게스트)" -> "김철수"
  /// 예: "[정회원] 박지성" -> "박지성"
  static final RegExp _cleanPrefixSuffixRegex = RegExp(
    r'(^[0-9]+[\.\)\-\:\s]*|\[.*?\]|\(.*?\)|<.*?>)',
  );

  /// 로컬 이미지 파일 경로에서 텍스트를 인식하여 유효한 참석자 목록을 파싱
  Future<List<Attendee>> parseFromImagePath(
    String imagePath, {
    Set<String> blacklist = defaultBlacklist,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    return parseFromRecognizedText(recognizedText, blacklist: blacklist);
  }

  /// ML Kit RecognizedText 객체로부터 참석자 이름 목록 추출
  List<Attendee> parseFromRecognizedText(
    RecognizedText recognizedText, {
    Set<String> blacklist = defaultBlacklist,
  }) {
    final List<Attendee> attendees = [];
    final Set<String> seenNames = {};

    for (final textBlock in recognizedText.blocks) {
      for (final textLine in textBlock.lines) {
        final rawLine = textLine.text.trim();
        if (rawLine.isEmpty) continue;

        final extractedNames = extractValidNamesFromLine(rawLine, blacklist: blacklist);

        for (final name in extractedNames) {
          if (!seenNames.contains(name)) {
            seenNames.add(name);
            attendees.add(
              Attendee(
                id: _uuid.v4(),
                name: name,
                originalRawText: rawLine,
              ),
            );
          }
        }
      }
    }

    return attendees;
  }

  /// 단일 텍스트 줄에서 유효한 한글 참석자 이름들을 추출
  List<String> extractValidNamesFromLine(
    String line, {
    Set<String> blacklist = defaultBlacklist,
  }) {
    final List<String> result = [];

    // 1단계: 괄호 및 접두/접미 번호 정제
    // 예: "1. 홍길동" -> "홍길동"
    String cleanedLine = line.replaceAll(_cleanPrefixSuffixRegex, ' ').trim();

    // 2단계: 공백이나 특수문자로 토큰 분리
    final tokens = cleanedLine.split(RegExp(r'[\s,\/\+\|]+'));

    for (final token in tokens) {
      // 순수 한글 글자만 추출
      final hangulOnly = token.replaceAll(RegExp(r'[^가-힣]'), '');

      if (isValidAttendeeName(hangulOnly, blacklist: blacklist)) {
        result.add(hangulOnly);
      }
    }

    // 만약 토큰 분리로 안 잡혔지만 라인 전체에서 2~4글자 한글이 발견되는 경우 보조 탐색
    if (result.isEmpty) {
      final matches = RegExp(r'[가-힣]{2,4}').allMatches(line);
      for (final match in matches) {
        final candidate = match.group(0)!;
        if (isValidAttendeeName(candidate, blacklist: blacklist)) {
          result.add(candidate);
        }
      }
    }

    return result;
  }

  /// 추출된 단어가 유효한 2~4글자 참석자 이름인지 판정
  bool isValidAttendeeName(
    String word, {
    Set<String> blacklist = defaultBlacklist,
  }) {
    // 1. 길이 및 한글 검사 (2~4글자)
    if (!_pureKoreanNameRegex.hasMatch(word)) {
      return false;
    }

    // 2. 블랙리스트 단어 포함 여부 검사
    if (blacklist.contains(word)) {
      return false;
    }

    // 3. 블랙리스트 단어가 접두/접미사로 포함된 경우 제외 (예: "투표자", "참석자", "인원수")
    for (final blacklisted in blacklist) {
      if (word.contains(blacklisted)) {
        return false;
      }
    }

    return true;
  }

  /// 리소스 해제
  Future<void> dispose() async {
    await _recognizer.close();
  }
}

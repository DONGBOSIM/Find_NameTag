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
    '도우미', '운영진', '매니저', '관리자', '남성', '여성',
    '초반', '중반', '후반', '첫참여', '신규',
  };

  /// 2~4글자 순수 한글 이름 정규식
  static final RegExp _pureKoreanNameRegex = RegExp(r'^[가-힣]{2,4}$');

  /// 괄호 내 3가지 파라미터 (이름/성별/거주지) 추출 패턴
  /// 예: "네로탱구 (심동보/남/목동) 목3동" -> "심동보"
  /// 예: "(이제혁/남/발산) 등촌제3동" -> "이제혁"
  /// 예: "후추(이준호/남/목동) 연희동" -> "이준호"
  static final RegExp _bracketProfileRegex = RegExp(
    r'[\(\[]\s*([^/\)\]\s]{2,4})\s*\/\s*[^/\)\]\s]+\s*\/\s*[^/\)\]\s]*[\)\]]',
  );

  /// 괄호 없이 슬래시로 구분된 프로필 패턴 (예외 입력 지원)
  /// 예: "김광현/남/목동 목3동" -> "김광현"
  /// 예: "위성명/남/발산 발산제1동" -> "위성명"
  static final RegExp _slashProfileRegex = RegExp(
    r'(?:^|\s)([가-힣]{2,4})\s*\/\s*(?:남|여|[가-힣])\s*\/',
  );

  /// 연령대/성별 등 프로필 부가 정보 메타데이터 라인 제외 패턴
  /// 예: "40대 초반 남성", "30대 초반 여성 · 첫 참여"
  static final RegExp _ageGenderMetadataRegex = RegExp(
    r'\d+대\s*(?:초반|중반|후반)?\s*(?:남성|여성)|첫\s*참여',
  );

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
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);
      return parseFromRecognizedText(recognizedText, blacklist: blacklist);
    } finally {
      await recognizer.close();
    }
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
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) return [];

    // 0단계: 연령대 및 성별 메타데이터 라인("40대 초반 남성" 등)은 프로필 파라미터가 없으면 제외
    if (_ageGenderMetadataRegex.hasMatch(trimmedLine)) {
      if (!_bracketProfileRegex.hasMatch(trimmedLine) &&
          !_slashProfileRegex.hasMatch(trimmedLine)) {
        return [];
      }
    }

    final List<String> result = [];

    // 1단계: 괄호 내 3가지 파라미터 (이름/성별/거주지) 중 첫 번째(이름) 추출 (최우선 순위)
    // 예: "네로탱구 (심동보/남/목동) 목3동" -> "심동보"
    // 예: "(이제혁/남/발산) 등촌제3동" -> "이제혁"
    // 예: "후추(이준호/남/목동) 연희동" -> "이준호"
    final bracketMatches = _bracketProfileRegex.allMatches(trimmedLine);
    for (final match in bracketMatches) {
      final rawCandidate = match.group(1) ?? '';
      final cleanCandidate = rawCandidate.replaceAll(RegExp(r'[^가-힣]'), '');
      if (isValidAttendeeName(cleanCandidate, blacklist: blacklist)) {
        result.add(cleanCandidate);
      }
    }

    if (result.isNotEmpty) {
      return result;
    }

    // 2단계: 괄호 없이 슬래시로 구분된 패턴 (예: "김광현/남/목동 목3동", "최재민/남/염창동")
    final slashMatches = _slashProfileRegex.allMatches(trimmedLine);
    for (final match in slashMatches) {
      final rawCandidate = match.group(1) ?? '';
      final cleanCandidate = rawCandidate.replaceAll(RegExp(r'[^가-힣]'), '');
      if (isValidAttendeeName(cleanCandidate, blacklist: blacklist)) {
        result.add(cleanCandidate);
      }
    }

    if (result.isNotEmpty) {
      return result;
    }

    // 3단계: 기존 투표 명단 파싱 (번호, 부가 괄호 등 수식어 제거 후 토큰 파싱)
    // 예: "1. 홍길동 (참석)" -> "홍길동"
    // 예: "3) 김철수(게스트)" -> "김철수"
    String cleanedLine = trimmedLine.replaceAll(_cleanPrefixSuffixRegex, ' ').trim();

    // 수식어를 정제한 후에도 '도우미', '운영진', '관리자' 등 시스템/제외 키워드가 포함된 라인은 건너뜀
    for (final kw in blacklist) {
      if (kw.length >= 2 && cleanedLine.contains(kw)) {
        return [];
      }
    }

    // 공백이나 특수문자로 토큰 분리
    final tokens = cleanedLine.split(RegExp(r'[\s,\/\+\|]+'));

    for (final token in tokens) {
      // 숫자가 포함된 토큰(예: 목5동, 등촌제1동, 1등)은 인명이 아니므로 제외
      if (RegExp(r'[0-9]').hasMatch(token)) continue;

      final hangulOnly = token.replaceAll(RegExp(r'[^가-힣]'), '');
      if (isValidAttendeeName(hangulOnly, blacklist: blacklist)) {
        result.add(hangulOnly);
      }
    }

    // 4단계: 토큰 분리로 안 잡혔지만 라인 전체에서 2~4글자 한글이 발견되는 경우 보조 탐색
    if (result.isEmpty) {
      final matches = RegExp(r'[가-힣]{2,4}').allMatches(trimmedLine);
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

    // 2. 블랙리스트 단어 정확 일치 검사
    if (blacklist.contains(word)) {
      return false;
    }

    // 3. 블랙리스트 단어가 접두/접미사로 포함된 경우 제외 (예: "투표자", "참석자", "인원수")
    // 단, '수', '목', '일' 등 한 글자 요일 키워드가 이름에 포함된 경우(예: '김수진', '이수현') 오탐 방지를 위해 2글자 이상 키워드만 부분 일치 검사
    for (final blacklisted in blacklist) {
      if (blacklisted.length >= 2 && word.contains(blacklisted)) {
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

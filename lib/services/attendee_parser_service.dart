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
    // 투표 및 시스템 용어
    '투표', '참석', '마감', '취소', '불참', '정회원', '게스트',
    '총무', '모임장', '인원', '요일', '배드민턴', '클럽', '회비',
    '운동', '벙개', '월', '화', '수', '목', '금', '토', '일',
    '오전', '오후', '시간', '시작', '종료', '마감됨', '투표자',
    '선택', '명단', '현황', '코트', '체육관', '준비', '완료',
    '참여', '멤버', '등록', '공지', '확인', '미정', '대기',
    '댓글', '사진', '동호회', '경기', '복식', '단식', '매칭',
    '도우미', '운영진', '매니저', '관리자', '남성', '여성',
    '초반', '중반', '후반', '첫참여', '신규', '참여중', '대기중',
    '민턴', '일정', '모임',

    // 주요 거주지 및 행정구역 명칭 (이름으로 오인되는 것 방지)
    '목동', '염창동', '염창', '가양동', '가양', '등촌동', '등촌',
    '화곡동', '화곡', '발산동', '내발산동', '외발산동', '발산',
    '우장산동', '우장산', '공항동', '방화동', '개화동', '신월동',
    '신정동', '양천', '강서', '구로', '신도림', '대림', '영등포',
    '문래동', '문래', '당산동', '당산', '여의도동', '여의도',
    '마포', '공덕', '상암동', '상암', '연희동', '연희', '신촌',
    '홍대', '서대문', '북가좌동', '남가좌동', '가좌동', '가좌',
    '은평', '불광', '관악구', '봉천동', '신림동', '동작', '사당',
    '서초', '강남', '송파', '잠실', '마곡동', '마곡', '중림동',
    '서울역', '오목교', '고척동', '인왕동', '관악',

    // 일반 닉네임 단어
    '두딸맘', '딸맘', '아들맘', '라디오', '탱구', '이즈백', '참꿈',
  };

  /// 2~4글자 순수 한글 이름 정규식
  static final RegExp _pureKoreanNameRegex = RegExp(r'^[가-힣]{2,4}$');

  /// 닉네임 전형 접미사/패턴 (예: 두딸맘, 민우맘, 고장난라디오 등)
  static final RegExp _nicknamePatternRegex = RegExp(
    r'(?:맘|파파|아빠|엄마|라디오|탱구|이즈백)$',
  );

  /// 괄호 내 프로필 추출 패턴 (각종 괄호 기호 및 다양한 구분자 지원)
  /// 예: "네로탱구 (심동보/남/목동) 목3동" -> "심동보/남/목동"
  /// 예: "참꿈777 (김민희,남,목동) 목동" -> "김민희,남,목동"
  /// 예: "고상난라디오(원석/남/서울역-오목교) 중림동" -> "원석/남/서울역-오목교"
  static final RegExp _bracketContentRegex = RegExp(
    r'[\(\[\{<（【〔]([^\)\]\}>）】\n]+)[\)\]\}>）】]?',
  );

  /// 괄호 없이 슬래시/쉼표/파이프로 구분된 프로필 패턴 (닉네임 없는 회원 지원)
  /// 예: "위성영/남/화곡 화곡제1동" -> "위성영"
  /// 예: "김광헌/남/목동 목3동" -> "김광헌"
  static final RegExp _slashProfileRegex = RegExp(
    r'(?:^|\s)([가-힣]{2,4})\s*[/,\|]\s*(?:남|여|남성|여성|[가-힣])(?:\s*[/,\|]|\s|$)',
  );

  /// 연령대/성별/투표 헤더 메타데이터 라인 제외 패턴
  /// 예: "40대 초반 남성", "30대 초반 여성 · 첫 참여", "참여 중 22", "10월 30일 금요일 민턴"
  static final RegExp _metadataLineRegex = RegExp(
    r'\d+대\s*(?:초반|중반|후반)?\s*(?:남성|여성)|첫\s*참여|참여\s*중\s*\d+|대기\s*중\s*\d+|\d+월\s*\d+일',
  );

  /// 투표 라인에서 번호, 괄호 등 수식어를 제거하고 순수 이름을 추출하기 위한 패턴
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

    // 0단계: 연령대, 성별, 투표 헤더("40대 초반 남성", "참여 중 22" 등) 라인 제외
    if (_metadataLineRegex.hasMatch(trimmedLine)) {
      if (!_bracketContentRegex.hasMatch(trimmedLine) &&
          !_slashProfileRegex.hasMatch(trimmedLine)) {
        return [];
      }
    }

    // 1단계 (최우선): 닉네임 (이름/성별/거주지) 형태에서 괄호 안의 이름 추출
    // 예: "네로탱구 (심동보/남/목동) 목3동" -> "심동보"
    // 예: "참꿈777 (김민희,남,목동) 목동" -> "김민희"
    // 예: "두딸맘 (김주희/여/염창동) 염창동" -> "김주희"
    // 예: "고상난라디오(원석/남/서울역-오목교) 중림동" -> "원석"
    final bracketMatches = _bracketContentRegex.allMatches(trimmedLine);
    for (final match in bracketMatches) {
      final insideContent = match.group(1)?.trim() ?? '';
      if (insideContent.isEmpty) continue;

      // 프로필 괄호인지 판별: 구분자(/, ,, |) 또는 성별(남, 여) 키워드가 괄호 안에 존재해야 함
      // 예: "(심동보/남/목동)", "(김민희,남,목동)" -> 프로필 괄호 (OK)
      // 예: "(참석)", "(게스트)" -> 단순 수식어 괄호 (3단계로 위임)
      final isProfileBracket = insideContent.contains('/') ||
          insideContent.contains(',') ||
          insideContent.contains('|') ||
          insideContent.contains('\\') ||
          RegExp(r'(?:남|여|남성|여성)').hasMatch(insideContent);

      if (!isProfileBracket) {
        continue;
      }

      // 괄호 내부를 슬래시(/), 쉼표(,), 파이프(|), 공백 등으로 분리
      final tokens = insideContent.split(RegExp(r'[/,\|\s\.\\]+'));
      for (final token in tokens) {
        final cleanCandidate = token.replaceAll(RegExp(r'[^가-힣]'), '');
        // 성별 토큰 제외
        if (cleanCandidate == '남' || cleanCandidate == '여' ||
            cleanCandidate == '남성' || cleanCandidate == '여성') {
          continue;
        }

        if (isValidAttendeeName(cleanCandidate, blacklist: blacklist)) {
          // 괄호 안에서 이름을 찾았으면 즉시 반환 (앞의 닉네임, 뒤의 거주지 오염 원천 차단)
          return [cleanCandidate];
        }
      }

      // 프로필 괄호였으나 유효한 이름을 찾지 못한 경우,
      // 괄호 밖 닉네임/거주지가 이름으로 오인되는 것을 방지하기 위해 스킵
      return [];
    }

    // 2단계: 닉네임 없는 회원 - 슬래시/쉼표로 구분된 형태 (이름/성별/거주지)
    // 예: "위성영/남/화곡 화곡제1동" -> "위성영"
    // 예: "김광헌/남/목동 목3동" -> "김광헌"
    final slashMatch = _slashProfileRegex.firstMatch(trimmedLine);
    if (slashMatch != null) {
      final rawCandidate = slashMatch.group(1) ?? '';
      final cleanCandidate = rawCandidate.replaceAll(RegExp(r'[^가-힣]'), '');
      if (isValidAttendeeName(cleanCandidate, blacklist: blacklist)) {
        // 첫 번째 항목(이름)을 찾았으면 즉시 반환 (뒤의 거주지 오염 원천 차단)
        return [cleanCandidate];
      }
    }

    // 3단계: 기존 단순 투표 명단 파싱 (번호, 부가 괄호 등 수식어 제거 후 토큰 파싱)
    // 예: "1. 홍길동 (참석)" -> "홍길동"
    // 예: "2) 김철수" -> "김철수"
    String cleanedLine = trimmedLine.replaceAll(_cleanPrefixSuffixRegex, ' ').trim();

    // 시스템 키워드가 포함된 라인은 건너뜀
    for (final kw in blacklist) {
      if (kw.length >= 2 && cleanedLine.contains(kw)) {
        return [];
      }
    }

    // 공백이나 특수문자로 토큰 분리
    final tokens = cleanedLine.split(RegExp(r'[\s,\/\+\|]+'));
    final List<String> result = [];

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

    // 2. 성별 단어 단독인 경우 제외
    if (word == '남' || word == '여' || word == '남성' || word == '여성') {
      return false;
    }

    // 3. 블랙리스트 단어 정확 일치 검사
    if (blacklist.contains(word)) {
      return false;
    }

    // 4. 닉네임 전형 접미사 검사 (두딸맘, 민우맘, 고장난라디오 등)
    if (_nicknamePatternRegex.hasMatch(word)) {
      return false;
    }

    // 5. 2글자 이상 블랙리스트 단어가 포함된 경우 제외
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

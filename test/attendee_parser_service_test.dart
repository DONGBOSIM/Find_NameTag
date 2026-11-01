import 'package:flutter_test/flutter_test.dart';
import 'package:find_nametag/services/attendee_parser_service.dart';

void main() {
  late AttendeeParserService parser;

  setUp(() {
    parser = AttendeeParserService();
  });

  group('AttendeeParserService - 괄호 내 파라미터 (이름/성별/거주지) 파싱 테스트', () {
    test('닉네임 (이름/성별/거주지) 형태에서 이름만 정확히 추출', () {
      const line1 = '네로탱구 (심동보/남/목동) 목3동';
      expect(parser.extractValidNamesFromLine(line1), ['심동보']);

      const line2 = '후추(이준호/남/목동) 연희동';
      expect(parser.extractValidNamesFromLine(line2), ['이준호']);

      const line3 = '반짝반짝 (김수진/여/목동) 목동';
      expect(parser.extractValidNamesFromLine(line3), ['김수진']);

      const line4 = '리사 (박유준/여/목동) 염창동';
      expect(parser.extractValidNamesFromLine(line4), ['박유준']);

      const line5 = '|||| (송유진/여/목동) 목2동';
      expect(parser.extractValidNamesFromLine(line5), ['송유진']);

      const line6 = '이즈백 (재호/남/강서) 우장산동';
      expect(parser.extractValidNamesFromLine(line6), ['재호']);

      const line7 = '싸나이 (백동현/남/등촌) 인왕동';
      expect(parser.extractValidNamesFromLine(line7), ['백동현']);

      const line8 = '하루 (박우진/남/염창동) 가양제3동';
      expect(parser.extractValidNamesFromLine(line8), ['박우진']);

      const line9 = '미미(성미령/여/고척동) 고척동';
      expect(parser.extractValidNamesFromLine(line9), ['성미령']);

      const line10 = '심종용 (심종용/남/목동) 목2동';
      expect(parser.extractValidNamesFromLine(line10), ['심종용']);

      const line11 = '토끼 (류한철/남/목동) 목동';
      expect(parser.extractValidNamesFromLine(line11), ['류한철']);

      const line12 = '쿠니(조종언/남/등촌) 등촌제1동';
      expect(parser.extractValidNamesFromLine(line12), ['조종언']);

      const line13 = '광떡 (이광호/남/관악구) 봉천동';
      expect(parser.extractValidNamesFromLine(line13), ['이광호']);

      const line14 = '이승우(이승우/남/목동) 목2동';
      expect(parser.extractValidNamesFromLine(line14), ['이승우']);

      const line15 = '아르나크(정진우/남/목동) 여의도동';
      expect(parser.extractValidNamesFromLine(line15), ['정진우']);

      const line16 = '(이제혁/남/발산) 등촌제3동';
      expect(parser.extractValidNamesFromLine(line16), ['이제혁']);

      const line17 = '민트초코맛딸기 (박인혁/남/신월동) 신월동';
      expect(parser.extractValidNamesFromLine(line17), ['박인혁']);

      const line18 = '챌림(염채린/여/강서) 등촌동';
      expect(parser.extractValidNamesFromLine(line18), ['염채린']);

      const line19 = '피꼬렛(한승은/여/마곡) 마곡동';
      expect(parser.extractValidNamesFromLine(line19), ['한승은']);
    });

    test('괄호 없이 슬래시로만 구분된 예외 케이스 추출', () {
      const line1 = '김광현/남/목동 목3동';
      expect(parser.extractValidNamesFromLine(line1), ['김광현']);

      const line2 = '위성명/남/발산 발산제1동';
      expect(parser.extractValidNamesFromLine(line2), ['위성명']);

      const line3 = '최재민/남/염창동 염창동';
      expect(parser.extractValidNamesFromLine(line3), ['최재민']);

      const line4 = '김성훈 남 목5동 목5동';
      expect(parser.extractValidNamesFromLine(line4), ['김성훈']);
    });

    test('연령/성별 부가 라인은 참석자 이름으로 오인하지 않음', () {
      expect(parser.extractValidNamesFromLine('40대 초반 남성'), isEmpty);
      expect(parser.extractValidNamesFromLine('30대 후반 여성'), isEmpty);
      expect(parser.extractValidNamesFromLine('20대 후반 남성'), isEmpty);
      expect(parser.extractValidNamesFromLine('30대 초반 여성 · 첫 참여'), isEmpty);
      expect(parser.extractValidNamesFromLine('무한젤리 도우미 화곡제3동'), isEmpty);
    });

    test('기존 투표 명단 포맷(번호, 참석 여부)도 정상 지원', () {
      expect(parser.extractValidNamesFromLine('1. 홍길동 (참석)'), ['홍길동']);
      expect(parser.extractValidNamesFromLine('2) 김철수'), ['김철수']);
    });
    test('사용자 실제 제보 투표 캡처본 20명 라인 전수 테스트', () {
      final cases = {
        '네로탱구 (심동보/남/목동) 목3동': '심동보',
        '붕붕(김유진/여/목동) 목4동': '김유진',
        '팅클언 (효선/여/목동) 목3동': '효선',
        '하루 (박우진/남/염창동) 가양제3동': '박우진',
        '참꿈777 (김민희,남,목동) 목동': '김민희',
        '후후(이준호/남/목동) 연희동': '이준호',
        '이즈백 (재호/남/강서) 우장산동': '재호',
        '아키 (윤영미/여/내발산동) 내발산동': '윤영미',
        '위성영/남/화곡 화곡제1동': '위성영',
        '고상난라디오(원석/남/서울역-오목교) 중림동': '원석',
        '두딸맘 (김주희/여/염창동) 염창동': '김주희',
        '주노(황순호/남/북가좌동) 북가좌동': '황순호',
        '이르니크(정진우/남/목동) 여의도동': '정진우',
        '김광헌/남/목동 목3동': '김광헌',
        '심중용 (심중용/남/목동) 목2동': '심중용',
        '리사 (박유준/여/목동) 염창동': '박유준',
        '팡꺽 (이광호/남/관악구) 봉천동': '이광호',
        '퀄림(엄채린/여/강서) 등촌동': '엄채린',
        '이승우(이승우/남/목동) 목2동': '이승우',
        '대쉬(김선호/남/목2동) 목2동': '김선호',
      };

      for (final entry in cases.entries) {
        final result = parser.extractValidNamesFromLine(entry.key);
        expect(result, [entry.value], reason: '실패한 라인: ${entry.key}');
      }
    });

    test('사용자 실제 제보 투표 캡처본 - 닉네임과 거주지만 단독으로 들어오는 경우 이름으로 오인 방지', () {
      expect(parser.extractValidNamesFromLine('두딸맘'), isEmpty);
      expect(parser.extractValidNamesFromLine('목동'), isEmpty);
      expect(parser.extractValidNamesFromLine('염창동'), isEmpty);
      expect(parser.extractValidNamesFromLine('화곡제1동'), isEmpty);
      expect(parser.extractValidNamesFromLine('연희동'), isEmpty);
      expect(parser.extractValidNamesFromLine('참여 중 22'), isEmpty);
      expect(parser.extractValidNamesFromLine('대기 중 0'), isEmpty);
    });
  });
}

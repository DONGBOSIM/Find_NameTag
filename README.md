# 🏸 배드민턴 클럽 매칭판 네임카드 자동 탐색 앱 (Flutter MVP)

배드민턴 동호회 참석 투표 캡처본(카카오톡, 밴드, 소모임)에서 참석자 명단을 자동 추출하고, 체육관 매칭판을 촬영하여 각 참석자의 자석 네임카드 위치를 찾아 카메라 화면 위에 시각적으로 형광 하이라이트 표시 및 코트 배치 체크를 지원하는 모바일 앱입니다.

---

## 🚀 주요 기능 및 파이프라인

### 1. 참석자 캡처본 파싱 (`AttendeeParserService`)
* **투표 캡처본 OCR**: `google_mlkit_text_recognition` 한글 모델 사용
* **정규식 필터링**: `^[가-힣]{2,4}$` (2~4글자 유효 한글 이름만 파싱)
* **스마트 블랙리스트 제외**: `"투표"`, `"참석"`, `"마감"`, `"취소"`, `"불참"`, `"정회원"`, `"게스트"`, `"총무"`, `"모임장"` 등 40여 개 동호회 키워드 자동 필터링
* **태그 칩 UI & 수동 관리**: 파싱된 이름을 태그 칩 형태로 시각화하며, 직접 추가 및 삭제 가능

### 2. 매칭판 촬영 및 네임카드 탐색 (`BoardDetectorService`)
* **매칭판 OCR**: 카메라 촬영 또는 앨범 선택을 통해 매칭판 내 모든 텍스트 블록 및 바운딩 박스(`Rect`) 추출
* **해상도 정규화**: 원본 이미지의 가로/세로 해상도 비율(`imageAspectRatio`)을 측정하여 반응형 좌표로 변환

### 3. 한글 자모 분리 퍼지 매칭 엔진 (`HangulFuzzyMatcher`)
체육관 조명 반사, 비닐 코팅, 촬영 각도로 인한 OCR 오인식(예: `'심동보'` ➔ `'심둥보'`)을 완벽하게 극복합니다:
* **유니코드 자모 분리**: 초성(19자), 중성(21자), 종성(28자) 유니코드 연산 분해
* **Levenshtein 편집 거리**:
  * `'심동보'` ➔ `ㅅㅣㅁㄷㅗㅇㅂㅗ` (8자모)
  * `'심둥보'` ➔ `ㅅㅣㅁㄷㅜㅇㅂㅗ` (8자모)
  * 편집 거리 = 1 ('ㅗ' ➔ 'ㅜ' 단 1회 치환)
  * 유사도 = $1.0 - (1 / 8) = \mathbf{87.5\%} \ge 75\%$ ➔ **매칭 성공!**
* **슬라이딩 윈도우 서브스트링 탐색**: 보드판 텍스트 블록에 `"[A조] 심둥보"` 처럼 앞뒤 글자가 섞여 있어도 부분 문자열 매칭

### 4. 결과 시각화 오버레이 UI (`MatchingResultScreen`)
* **`InteractiveViewer`**: 원본 이미지 비율을 유지하며 자유로운 핀치 줌 & 팬 지원
* **`CustomPainter` (`BoundingBoxPainter`)**:
  * 미체크 상태: 눈에 확 띄는 Vibrant Cyan/Lime 형광 네온 테두리 + 상단 이름/유사도 라벨 배지
  * 체크 완료 상태: 회색 반투명 오버레이 + 체크(✓) 마크
* **인터랙티브 코트 배치 체크**:
  * 매칭된 바운딩 박스를 탭하거나 하단 [오늘 참석자 목록] 칩을 터치하면 '코트 꽂힘 완료' 토글
  * 매칭판에서 찾지 못한 인원은 '미발견' 경고 배너로 직관적 안내

---

## 📁 프로젝트 폴더 구조

```
lib/
├── models/
│   ├── attendee.dart              # 참석자 모델 (이름, 체크상태, 매칭상태)
│   ├── name_card_match.dart       # 보드판 매칭 정보 (바운딩박스 Rect, 유사도)
│   ├── board_scan_result.dart     # 매칭판 종합 스캔 결과 모델
│   └── models.dart                # Barrel export
├── services/
│   ├── hangul_fuzzy_matcher.dart  # 초/중/종성 분리 및 Levenshtein 퍼지 매칭 엔진
│   ├── attendee_parser_service.dart # 투표 캡처본 한글 이름 파서 및 블랙리스트
│   ├── board_detector_service.dart  # 매칭판 OCR 좌표 추출 및 1:1 최적 매칭
│   └── services.dart              # Barrel export
├── providers/
│   ├── attendees_provider.dart    # 참석자 목록 상태 관리 (Riverpod)
│   ├── board_scan_provider.dart   # 매칭판 스캔 및 체크 상태 관리 (Riverpod)
│   └── providers.dart             # Barrel export
├── views/
│   ├── home_screen.dart           # 홈 대시보드 및 단계별 카드
│   ├── attendee_list_screen.dart  # 1단계: 캡처본 등록 및 참석자 칩 관리
│   ├── board_scan_screen.dart     # 2단계: 카메라 촬영 가이드 뷰파인더
│   ├── matching_result_screen.dart# 3단계: 인터랙티브 뷰어 & CustomPainter 오버레이
│   └── views.dart                 # Barrel export
├── widgets/
│   ├── bounding_box_painter.dart  # 네온 하이라이트 및 히트테스트 CustomPainter
│   ├── attendee_chip.dart         # 상태별 태그 칩 (발견/체크/미발견)
│   ├── unmatched_warning_card.dart# 미발견 참석자 경고 배너
│   └── widgets.dart               # Barrel export
└── main.dart                      # ProviderScope 및 다크 스포츠 테마 설정
```

---

## 🛠 실행 방법

```bash
# 1. 패키지 의존성 다운로드
flutter pub get

# 2. 자모 분리 및 퍼지 매칭 단위 테스트 실행
flutter test test/hangul_fuzzy_matcher_test.dart

# 3. 디바이스에서 실행 (Android/iOS)
flutter run
```

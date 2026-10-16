import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';

import '../models/attendee.dart';
import '../models/board_scan_result.dart';
import '../models/name_card_match.dart';
import 'hangul_fuzzy_matcher.dart';

/// 후보 매칭 정보 내부 헬퍼
class _MatchCandidate {
  final Attendee attendee;
  final TextLine detectedLine;
  final FuzzyMatchResult matchResult;

  _MatchCandidate({
    required this.attendee,
    required this.detectedLine,
    required this.matchResult,
  });
}

/// 체육관 매칭판을 촬영하거나 선택한 이미지에서
/// ML Kit Text Recognizer를 실행하고 자모 퍼지 매칭을 통해
/// 각 참석자의 자석 네임카드 위치(Bounding Box)를 검출하는 서비스
class BoardDetectorService {
  final TextRecognizer _recognizer;
  final Uuid _uuid = const Uuid();

  BoardDetectorService({TextRecognizer? recognizer})
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.korean);

  /// 매칭판 이미지와 참석자 리스트를 받아 네임카드 탐색 및 매핑 실행
  Future<BoardScanResult> detectAndMatch({
    required String imagePath,
    required List<Attendee> attendees,
    double threshold = HangulFuzzyMatcher.defaultThreshold,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    // 1. 이미지 실제 해상도(width, height) 로드
    final imageSize = await _getImageSize(imagePath);

    // 2. ML Kit 온디바이스 한글 OCR 실행
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    // 3. 매칭판에서 감지된 모든 텍스트 라인 및 바운딩 박스 수집
    final List<TextLine> allLines = [];
    final List<RawOcrDetection> rawDetections = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allLines.add(line);
        rawDetections.add(
          RawOcrDetection(
            text: line.text,
            boundingBox: line.boundingBox,
            confidence: line.confidence,
          ),
        );
      }
    }

    // 4. 모든 참석자와 감지된 텍스트 라인 간의 퍼지 매칭 후보군 산출
    final List<_MatchCandidate> candidates = [];

    for (final attendee in attendees) {
      for (final line in allLines) {
        final fuzzyResult = HangulFuzzyMatcher.match(
          attendee.name,
          line.text,
          threshold: threshold,
        );

        if (fuzzyResult.isMatched) {
          candidates.add(
            _MatchCandidate(
              attendee: attendee,
              detectedLine: line,
              matchResult: fuzzyResult,
            ),
          );
        }
      }
    }

    // 5. 유사도 높은 순으로 정렬하여 1:1 최적 매칭 수행 (중복 할당 방지)
    candidates.sort((a, b) => b.matchResult.similarity.compareTo(a.matchResult.similarity));

    final Set<String> matchedAttendeeIds = {};
    final Set<TextLine> matchedLines = {};
    final List<NameCardMatch> matches = [];

    for (final candidate in candidates) {
      final attendee = candidate.attendee;
      final line = candidate.detectedLine;

      if (!matchedAttendeeIds.contains(attendee.id) && !matchedLines.contains(line)) {
        matchedAttendeeIds.add(attendee.id);
        matchedLines.add(line);

        final matchId = _uuid.v4();
        final rawBox = line.boundingBox;

        // 정규화 좌표 계산 (0.0 ~ 1.0)
        final normalizedRect = ui.Rect.fromLTWH(
          imageSize.width > 0 ? rawBox.left / imageSize.width : 0.0,
          imageSize.height > 0 ? rawBox.top / imageSize.height : 0.0,
          imageSize.width > 0 ? rawBox.width / imageSize.width : 0.0,
          imageSize.height > 0 ? rawBox.height / imageSize.height : 0.0,
        );

        matches.add(
          NameCardMatch(
            id: matchId,
            attendeeId: attendee.id,
            attendeeName: attendee.name,
            detectedText: line.text,
            similarity: candidate.matchResult.similarity,
            boundingBox: rawBox,
            normalizedRect: normalizedRect,
            isChecked: attendee.isChecked,
            attendeeJamo: candidate.matchResult.attendeeJamo,
            detectedJamo: candidate.matchResult.detectedJamo,
          ),
        );
      }
    }

    // 6. 매칭판에서 찾지 못한 미발견 참석자 목록 추출
    final List<Attendee> unmatchedAttendees = attendees
        .where((a) => !matchedAttendeeIds.contains(a.id))
        .map((a) => a.copyWith(isMatched: false, matchedNameCardId: null))
        .toList();

    return BoardScanResult(
      imagePath: imagePath,
      imageWidth: imageSize.width,
      imageHeight: imageSize.height,
      matches: matches,
      unmatchedAttendees: unmatchedAttendees,
      otherDetections: rawDetections.where((d) {
        return !matches.any((m) => m.detectedText == d.text && m.boundingBox == d.boundingBox);
      }).toList(),
      scannedAt: DateTime.now(),
    );
  }

  /// 이미지 파일로부터 가로/세로 픽셀 크기 획득
  Future<ui.Size> _getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } catch (e) {
      debugPrint('Failed to get image dimensions: $e');
      // 기본값 폴백
      return const ui.Size(1080, 1920);
    }
  }

  /// 리소스 해제
  Future<void> dispose() async {
    await _recognizer.close();
  }
}

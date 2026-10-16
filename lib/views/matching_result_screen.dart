import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendee.dart';
import '../models/board_scan_result.dart';
import '../models/name_card_match.dart';
import '../providers/attendees_provider.dart';
import '../providers/board_scan_provider.dart';
import '../widgets/attendee_chip.dart';
import '../widgets/bounding_box_painter.dart';
import '../widgets/unmatched_warning_card.dart';
import 'board_scan_screen.dart';

class MatchingResultScreen extends ConsumerStatefulWidget {
  const MatchingResultScreen({super.key});

  @override
  ConsumerState<MatchingResultScreen> createState() => _MatchingResultScreenState();
}

class _MatchingResultScreenState extends ConsumerState<MatchingResultScreen> {
  final TransformationController _transformationController = TransformationController();
  String? _selectedMatchId;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// 캔버스 영역 탭 시 바운딩 박스 히트테스트 수행
  void _handleCanvasTap(
    TapUpDetails details,
    Size canvasSize,
    Size imageSize,
    List<NameCardMatch> matches,
  ) {
    final localPosition = details.localPosition;
    final hitMatch = BoundingBoxPainter.findHitMatch(
      localPosition: localPosition,
      canvasSize: canvasSize,
      imageSize: imageSize,
      matches: matches,
    );

    if (hitMatch != null) {
      HapticFeedback.lightImpact();
      ref.read(boardScanProvider.notifier).toggleMatchCheck(hitMatch.id);
      setState(() {
        _selectedMatchId = hitMatch.id;
      });

      final isNowChecked = !hitMatch.isChecked;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          backgroundColor: isNowChecked ? const Color(0xFF37474F) : const Color(0xFF00E5FF),
          content: Text(
            isNowChecked
                ? '🏸 "${hitMatch.attendeeName}" 님 명찰 코트 배치 완료 (체크)'
                : '↩ "${hitMatch.attendeeName}" 님 명찰 체크 취소',
            style: TextStyle(
              color: isNowChecked ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResultState = ref.watch(boardScanProvider);
    final BoardScanResult? result = scanResultState.value;
    final allAttendees = ref.watch(attendeesProvider).value ?? [];

    if (result == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121418),
        appBar: AppBar(title: const Text('매칭 결과')),
        body: const Center(
          child: Text(
            '스캔 결과가 없습니다.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final Size imageSize = Size(result.imageWidth, result.imageHeight);

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222B),
        elevation: 0,
        title: const Text(
          '매칭판 네임카드 탐색 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '매칭판 다시 촬영',
            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00FF88)),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BoardScanScreen()),
              );
            },
          ),
          IconButton(
            tooltip: '화면 비율 리셋',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 상단 통계 상태 요약 바
          _buildSummaryHeader(result),

          // 2. 미발견 참석자가 있을 경우 경고 배너 표시
          if (result.unmatchedAttendees.isNotEmpty)
            UnmatchedWarningCard(
              unmatchedAttendees: result.unmatchedAttendees,
              onRetryScan: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const BoardScanScreen()),
                );
              },
            ),

          // 3. 매칭판 원본 비율 인터랙티브 뷰어 (InteractiveViewer & CustomPainter)
          Expanded(
            child: ClipRect(
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 6.0,
                  boundaryMargin: const EdgeInsets.all(40),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: result.imageAspectRatio,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final canvasSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // 원본 이미지 렌더링
                              _buildBoardImage(result.imagePath),

                              // 바운딩 박스 및 터치 감지 오버레이
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) => _handleCanvasTap(
                                  details,
                                  canvasSize,
                                  imageSize,
                                  result.matches,
                                ),
                                child: CustomPaint(
                                  size: canvasSize,
                                  painter: BoundingBoxPainter(
                                    matches: result.matches,
                                    imageSize: imageSize,
                                    selectedMatchId: _selectedMatchId,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. 하단: [오늘 참석자 목록] 수평 슬라이더 칩 영역
          _buildBottomAttendeeSlider(allAttendees, result),
        ],
      ),
    );
  }

  /// 보드판 이미지 렌더링 헬퍼 (로컬 파일 또는 목업)
  Widget _buildBoardImage(String imagePath) {
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }
    // 이미지를 찾을 수 없을 때의 플레이스홀더
    return Container(
      color: const Color(0xFF1E222B),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }

  /// 상단 현황 통계 헤더 위젯
  Widget _buildSummaryHeader(BoardScanResult result) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E222B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            label: '전체 참석',
            value: '${result.totalAttendeeCount}명',
            color: Colors.white,
          ),
          _divider(),
          _statItem(
            label: '보드판 발견',
            value: '${result.matchCount}명',
            color: const Color(0xFF00E5FF),
          ),
          _divider(),
          _statItem(
            label: '코트 꽂힘(완료)',
            value: '${result.checkedCount}명',
            color: const Color(0xFF00FF88),
          ),
          _divider(),
          _statItem(
            label: '미발견',
            value: '${result.unmatchedCount}명',
            color: result.unmatchedCount > 0
                ? const Color(0xFFFF9100)
                : Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF90A4AE),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.shade800,
    );
  }

  /// 하단 오늘 참석자 목록 슬라이더
  Widget _buildBottomAttendeeSlider(
    List dynamicAttendees,
    BoardScanResult result,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    '오늘 참석자 목록',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '명찰 박스나 칩을 터치하여 코트 배치(체크 완료) 토글',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: result.matches.length + result.unmatchedAttendees.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  // 매칭된 인원 우선, 뒤이어 미발견 인원 나열
                  if (index < result.matches.length) {
                    final match = result.matches[index];
                    final attendee = Attendee(
                      id: match.attendeeId ?? match.id,
                      name: match.attendeeName,
                      isMatched: true,
                      isChecked: match.isChecked,
                      similarity: match.similarity,
                    );

                    return AttendeeChip(
                      attendee: attendee,
                      isSelected: _selectedMatchId == match.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(boardScanProvider.notifier)
                            .toggleMatchCheck(match.id);
                        setState(() {
                          _selectedMatchId = match.id;
                        });
                      },
                    );
                  } else {
                    final unmatchedIndex = index - result.matches.length;
                    final attendee = result.unmatchedAttendees[unmatchedIndex];
                    return AttendeeChip(
                      attendee: attendee,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '"${attendee.name}" 님은 매칭판에서 감지되지 않았습니다. 명찰이 부착되어 있는지 확인해 주세요.',
                            ),
                            backgroundColor: const Color(0xFFFF9100),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

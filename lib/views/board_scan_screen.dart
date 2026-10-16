import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/attendees_provider.dart';
import '../providers/board_scan_provider.dart';
import 'matching_result_screen.dart';

class BoardScanScreen extends ConsumerStatefulWidget {
  const BoardScanScreen({super.key});

  @override
  ConsumerState<BoardScanScreen> createState() => _BoardScanScreenState();
}

class _BoardScanScreenState extends ConsumerState<BoardScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _statusMessage = '';

  /// 카메라 또는 갤러리에서 매칭판 사진 획득 후 스캔 분석 실행
  Future<void> _captureOrPickBoard(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );

      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = '매칭판 한글 텍스트 감지 및 위치 좌표 추출 중...';
      });

      final attendees = ref.read(attendeesProvider).value ?? [];

      // 자모 퍼지 매칭 및 바운딩 박스 탐색 수행
      await ref.read(boardScanProvider.notifier).scanBoard(
            imagePath: image.path,
            attendees: attendees,
          );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        final scanResult = ref.read(boardScanProvider).value;
        if (scanResult != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MatchingResultScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스캔 실패: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendees = ref.watch(attendeesProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222B),
        elevation: 0,
        title: const Text(
          '2단계: 매칭판 촬영 및 탐색',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 가이드라인 및 설명 뷰
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 가이드 뷰파인더 목업
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 모서리 L자형 가이드 마크
                      ..._buildCornerMarkers(),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.crop_free,
                            size: 64,
                            color: const Color(0xFF00FF88).withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '체육관 매칭판 전체가 사각형 안에\n모두 들어오도록 촬영해 주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '조명 반사가 심할 경우 살짝 비스듬히 촬영하면\n자모 퍼지 매칭 엔진이 더 잘 인식합니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF90A4AE),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 현재 매칭 대상자 수 요약
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, color: Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '탐색 대상 참석자: ${attendees.length}명',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // 촬영 및 갤러리 선택 버튼
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _captureOrPickBoard(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.camera_alt, size: 22),
                        label: const Text(
                          '매칭판 카메라 촬영',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _captureOrPickBoard(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3240),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library, size: 20),
                        label: const Text(
                          '앨범',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 스캔 처리 중 풀스크린 로딩 오버레이
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF00FF88),
                        strokeWidth: 3.5,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AI 네임카드 자동 탐색 중',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    return [
      Positioned(
        top: 12,
        left: 12,
        child: _cornerBracket(isTop: true, isLeft: true),
      ),
      Positioned(
        top: 12,
        right: 12,
        child: _cornerBracket(isTop: true, isLeft: false),
      ),
      Positioned(
        bottom: 12,
        left: 12,
        child: _cornerBracket(isTop: false, isLeft: true),
      ),
      Positioned(
        bottom: 12,
        right: 12,
        child: _cornerBracket(isTop: false, isLeft: false),
      ),
    ];
  }

  Widget _cornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF00FF88), width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF00FF88), width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF00FF88), width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF00FF88), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

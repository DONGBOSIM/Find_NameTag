import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendee.dart';
import '../models/board_scan_result.dart';
import '../services/board_detector_service.dart';
import 'attendees_provider.dart';

/// 보드 디텍터 서비스 Provider
final boardDetectorServiceProvider = Provider<BoardDetectorService>((ref) {
  final service = BoardDetectorService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 매칭판 스캔 상태 관리 Notifier
class BoardScanNotifier extends StateNotifier<AsyncValue<BoardScanResult?>> {
  final BoardDetectorService _detectorService;
  final Ref _ref;

  BoardScanNotifier(this._detectorService, this._ref)
      : super(const AsyncValue.data(null));

  /// 매칭판 이미지 경로와 참석자 명단을 전달받아 스캔 및 퍼지 매칭 실행
  Future<void> scanBoard({
    required String imagePath,
    required List<Attendee> attendees,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _detectorService.detectAndMatch(
        imagePath: imagePath,
        attendees: attendees,
      );

      // 참석자 프로바이더에도 매칭 상태 동기화
      final matchedIds = result.matches
          .where((m) => m.attendeeId != null)
          .map((m) => m.attendeeId!)
          .toSet();
      final attendeeToMatchMap = {
        for (final m in result.matches)
          if (m.attendeeId != null) m.attendeeId!: m.id,
      };

      _ref.read(attendeesProvider.notifier).updateMatchingStates(
            matchedAttendeeIds: matchedIds,
            attendeeToMatchMap: attendeeToMatchMap,
          );

      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 특정 네임카드 바운딩 박스를 탭했을 때 체크 상태 토글
  void toggleMatchCheck(String matchId) {
    final currentResult = state.value;
    if (currentResult == null) return;

    final updated = currentResult.toggleMatchCheck(matchId);
    state = AsyncValue.data(updated);

    // 해당 참석자 체크 상태도 동기화
    final match = updated.matches.firstWhere((m) => m.id == matchId);
    if (match.attendeeId != null) {
      _ref.read(attendeesProvider.notifier).toggleCheck(match.attendeeId!);
    }
  }

  /// 하단 참석자 칩을 탭했을 때 체크 상태 토글
  void toggleAttendeeCheck(String attendeeId) {
    final currentResult = state.value;
    if (currentResult == null) return;

    final updated = currentResult.toggleAttendeeCheck(attendeeId);
    state = AsyncValue.data(updated);

    _ref.read(attendeesProvider.notifier).toggleCheck(attendeeId);
  }

  /// 스캔 결과 리셋
  void resetScan() {
    state = const AsyncValue.data(null);
  }
}

/// 전역 매칭판 스캔 Provider
final boardScanProvider =
    StateNotifierProvider<BoardScanNotifier, AsyncValue<BoardScanResult?>>((ref) {
  final detector = ref.watch(boardDetectorServiceProvider);
  return BoardScanNotifier(detector, ref);
});

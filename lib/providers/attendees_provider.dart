import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/attendee.dart';
import '../services/attendee_parser_service.dart';

/// 서비스 의존성 Provider
final attendeeParserServiceProvider = Provider<AttendeeParserService>((ref) {
  final service = AttendeeParserService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 참석자 목록 상태를 관리하는 StateNotifier
class AttendeesNotifier extends StateNotifier<AsyncValue<List<Attendee>>> {
  final AttendeeParserService _parserService;
  final Uuid _uuid = const Uuid();

  AttendeesNotifier(this._parserService) : super(const AsyncValue.data([]));

  /// 캡처본 단일 이미지 파일 경로를 받아 참석자 파싱 실행
  Future<void> parseFromImage(String imagePath) async {
    await parseFromMultipleImages([imagePath]);
  }

  /// 여러 캡처본 이미지 파일 경로를 받아 순차 파싱 및 통합 누적 실행
  Future<int> parseFromMultipleImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return 0;
    state = const AsyncValue.loading();
    try {
      final currentList = state.value ?? [];
      final existingNames = currentList.map((a) => a.name).toSet();
      final newAttendees = <Attendee>[...currentList];
      int newlyAddedCount = 0;

      for (final path in imagePaths) {
        final parsedList = await _parserService.parseFromImagePath(path);
        for (final attendee in parsedList) {
          if (!existingNames.contains(attendee.name)) {
            newAttendees.add(attendee);
            existingNames.add(attendee.name);
            newlyAddedCount++;
          }
        }
      }

      state = AsyncValue.data(newAttendees);
      return newlyAddedCount;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 사용자가 직접 참석자 이름 수동 추가
  bool addAttendee(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    final currentList = state.value ?? [];
    if (currentList.any((a) => a.name == cleanName)) {
      return false; // 중복
    }

    final newAttendee = Attendee(
      id: _uuid.v4(),
      name: cleanName,
    );

    state = AsyncValue.data([...currentList, newAttendee]);
    return true;
  }

  /// 참석자 삭제
  void removeAttendee(String id) {
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((a) => a.id != id).toList());
  }

  /// 참석자 코트 배치(체크) 토글
  void toggleCheck(String id) {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.map((a) {
        if (a.id == id) {
          return a.copyWith(isChecked: !a.isChecked);
        }
        return a;
      }).toList(),
    );
  }

  /// 전체 참석자 목록 초기화
  void clearAll() {
    state = const AsyncValue.data([]);
  }

  /// 매칭 스캔 결과로 참석자 목록 상태 일괄 동기화
  void updateMatchingStates({
    required Set<String> matchedAttendeeIds,
    required Map<String, String> attendeeToMatchMap,
  }) {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.map((a) {
        final isMatched = matchedAttendeeIds.contains(a.id);
        return a.copyWith(
          isMatched: isMatched,
          matchedNameCardId: attendeeToMatchMap[a.id],
        );
      }).toList(),
    );
  }
}

/// 전역 참석자 Provider
final attendeesProvider =
    StateNotifierProvider<AttendeesNotifier, AsyncValue<List<Attendee>>>((ref) {
  final parser = ref.watch(attendeeParserServiceProvider);
  return AttendeesNotifier(parser);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attendee.dart';
import '../providers/attendees_provider.dart';
import '../widgets/attendee_chip.dart';
import 'board_scan_screen.dart';

class AttendeeListScreen extends ConsumerStatefulWidget {
  const AttendeeListScreen({super.key});

  @override
  ConsumerState<AttendeeListScreen> createState() => _AttendeeListScreenState();
}

class _AttendeeListScreenState extends ConsumerState<AttendeeListScreen> {
  final TextEditingController _nameInputController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameInputController.dispose();
    super.dispose();
  }

  /// 갤러리에서 캡처본 이미지 선택 후 파싱
  Future<void> _pickImageAndParse(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        await ref
            .read(attendeesProvider.notifier)
            .parseFromImage(pickedFile.path);

        if (mounted) {
          final count = ref.read(attendeesProvider).value?.length ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('캡처본에서 총 $count명의 참석자를 추출했습니다!'),
              backgroundColor: const Color(0xFF00E5FF),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 파싱 중 오류 발생: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 수동 참석자 추가
  void _addManualName() {
    final name = _nameInputController.text.trim();
    if (name.isEmpty) return;

    final success = ref.read(attendeesProvider.notifier).addAttendee(name);
    if (success) {
      _nameInputController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 등록되어 있는 이름입니다.'),
          backgroundColor: Color(0xFFFF9100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendeesState = ref.watch(attendeesProvider);
    final attendees = attendeesState.value ?? [];
    final isLoading = attendeesState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222B),
        elevation: 0,
        title: const Text(
          '1단계: 참석자 명단 등록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        actions: [
          if (attendees.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(attendeesProvider.notifier).clearAll();
              },
              child: const Text(
                '전체 삭제',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 캡처본 불러오기 액션 영역
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E222B),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => _pickImageAndParse(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text(
                          '투표 캡처본 불러오기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: isLoading
                          ? null
                          : () => _pickImageAndParse(ImageSource.camera),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3240),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 수동 입력 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameInputController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '직접 이름 추가 (예: 홍길동)',
                          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF121418),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade800),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade800),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                          ),
                        ),
                        onSubmitted: (_) => _addManualName(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addManualName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3240),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 로딩 인디케이터
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  SizedBox(height: 12),
                  Text(
                    '한글 OCR로 참석자 명단을 파싱하는 중...',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 13),
                  ),
                ],
              ),
            ),

          // 추출된 명단 목록 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  '참석자 목록 (${attendees.length}명)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Text(
                  '칩을 터치하여 삭제 가능',
                  style: TextStyle(color: Color(0xFF78909C), fontSize: 11),
                ),
              ],
            ),
          ),

          // 참석자 태그 칩 그리드/랩 뷰
          Expanded(
            child: attendees.isEmpty && !isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.how_to_reg_outlined,
                          size: 56,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '등록된 참석자가 없습니다.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '투표 캡처본을 올리거나 상단에서 직접 추가하세요.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attendees.map((attendee) {
                        return AttendeeChip(
                          attendee: attendee,
                          showDeleteButton: true,
                          onDelete: () {
                            ref
                                .read(attendeesProvider.notifier)
                                .removeAttendee(attendee.id);
                          },
                        );
                      }).toList(),
                    ),
                  ),
          ),

          // 하단 다음 단계 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222B),
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: attendees.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BoardScanScreen(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade800,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    '매칭판 탐색 시작 (${attendees.length}명)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

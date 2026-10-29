import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/attendees_provider.dart';
import '../theme/app_theme.dart';
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

  /// 갤러리에서 여러 장의 캡처본 이미지 선택 후 파싱
  Future<void> _pickMultiImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        final paths = pickedFiles.map((file) => file.path).toList();
        final addedCount = await ref
            .read(attendeesProvider.notifier)
            .parseFromMultipleImages(paths);

        if (mounted) {
          final totalCount = ref.read(attendeesProvider).value?.length ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '캡처본 ${pickedFiles.length}장에서 새 참석자 $addedCount명을 추가했습니다! (총 $totalCount명)',
              ),
              backgroundColor: const Color(0xFF00E5FF),
              behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 카메라로 직접 캡처본 촬영 후 파싱
  Future<void> _pickCameraImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        final addedCount = await ref
            .read(attendeesProvider.notifier)
            .parseFromMultipleImages([pickedFile.path]);

        if (mounted) {
          final totalCount = ref.read(attendeesProvider).value?.length ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '촬영본에서 새 참석자 $addedCount명을 추가했습니다! (총 $totalCount명)',
              ),
              backgroundColor: const Color(0xFF00E5FF),
              behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        title: Text(
          '1단계: 참석자 명단 등록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: context.textPrimary,
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
            color: context.cardBg,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => _pickMultiImagesFromGallery(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryAccent,
                          foregroundColor: context.isDarkMode ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text(
                          '투표 캡처본 불러오기 (여러 장 가능)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: '카메라로 직접 촬영',
                      onPressed: isLoading
                          ? null
                          : () => _pickCameraImage(),
                      style: IconButton.styleFrom(
                        backgroundColor: context.isDarkMode
                            ? const Color(0xFF2C3240)
                            : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: Icon(Icons.camera_alt_outlined, color: context.textPrimary),
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
                        style: TextStyle(color: context.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '직접 이름 추가 (예: 홍길동)',
                          hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: context.inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.primaryAccent),
                          ),
                        ),
                        onSubmitted: (_) => _addManualName(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addManualName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.isDarkMode
                            ? const Color(0xFF2C3240)
                            : Colors.grey.shade200,
                        foregroundColor: context.textPrimary,
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
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: context.primaryAccent),
                  const SizedBox(height: 12),
                  Text(
                    '한글 OCR로 참석자 명단을 파싱하는 중...',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
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
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '칩을 터치하여 삭제 가능',
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
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
                          color: context.isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '등록된 참석자가 없습니다.',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '투표 캡처본을 올리거나 상단에서 직접 추가하세요.',
                          style: TextStyle(
                            color: context.isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade500,
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
              color: context.cardBg,
              border: Border(top: BorderSide(color: context.cardBorder)),
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
                    backgroundColor: context.secondaryAccent,
                    foregroundColor: context.isDarkMode ? Colors.black : Colors.white,
                    disabledBackgroundColor: context.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
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

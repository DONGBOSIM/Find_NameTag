import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendee.dart';
import '../providers/attendees_provider.dart';
import 'attendee_list_screen.dart';
import 'board_scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesState = ref.watch(attendeesProvider);
    final attendees = attendeesState.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis,
                color: Color(0xFF00E5FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '배드민턴 명찰 찾기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 인트로 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF102A43)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AI 한글 온디바이스 OCR',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '동호회 투표 캡처본으로\n매칭판 명찰을 1초 만에 찾기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '조명 반사나 코팅으로 이름이 왜곡되어도\n한글 자모 퍼지 매칭 엔진이 정확하게 찾아냅니다.',
                    style: TextStyle(
                      color: Color(0xFFB0BEC5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '단계별 진행',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 1단계: 참석자 명단 등록 카드
            _StepCard(
              stepNumber: '1',
              title: '참석자 명단 등록',
              subtitle: attendees.isEmpty
                  ? '카톡/밴드 투표 캡처본을 올리거나 직접 입력하세요.'
                  : '현재 등록된 참석자: ${attendees.length}명',
              icon: Icons.people_alt_outlined,
              accentColor: const Color(0xFF00E5FF),
              badgeText: attendees.isNotEmpty ? '${attendees.length}명 등록됨' : null,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendeeListScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // 2단계: 매칭판 촬영 및 네임카드 탐색 카드
            _StepCard(
              stepNumber: '2',
              title: '체육관 매칭판 촬영 및 탐색',
              subtitle: '매칭판을 촬영하면 참석자 명찰 위치를 하이라이트합니다.',
              icon: Icons.camera_alt_outlined,
              accentColor: const Color(0xFF00FF88),
              isEnabled: attendees.isNotEmpty,
              onTap: () {
                if (attendees.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('먼저 1단계에서 참석자 명단을 등록해 주세요!'),
                      backgroundColor: Color(0xFFFF9100),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BoardScanScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // 간편 테스트용 프리셋 버튼 (빠른 시연 지원)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  _loadSampleAttendees(ref);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('테스트용 샘플 참석자 8명이 등록되었습니다!'),
                      backgroundColor: Color(0xFF00E5FF),
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on, color: Color(0xFFFF9100), size: 18),
                label: const Text(
                  '테스트용 샘플 참석자 불러오기 ("심동보", "김민수" 등)',
                  style: TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadSampleAttendees(WidgetRef ref) {
    final samples = [
      '심동보',
      '김민수',
      '박지성',
      '이영희',
      '최유진',
      '강동원',
      '손흥민',
      '정우성',
    ];
    final notifier = ref.read(attendeesProvider.notifier);
    notifier.clearAll();
    for (final name in samples) {
      notifier.addAttendee(name);
    }
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final bool isEnabled;
  final VoidCallback onTap;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled
                  ? accentColor.withOpacity(0.4)
                  : Colors.grey.shade800,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? accentColor.withOpacity(0.15)
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isEnabled ? accentColor : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$stepNumber단계: $title',
                          style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isEnabled
                            ? const Color(0xFF90A4AE)
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? accentColor : Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

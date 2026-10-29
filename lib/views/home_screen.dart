import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/attendees_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'attendee_list_screen.dart';
import 'board_scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesState = ref.watch(attendeesProvider);
    final attendees = attendeesState.value ?? [];
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_tennis,
                    color: context.primaryAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.primaryAccent.withOpacity(0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                AppConstants.versionString,
                style: TextStyle(
                  color: context.primaryAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '화면 테마 설정',
            icon: Icon(
              switch (themeMode) {
                ThemeMode.system => Icons.brightness_auto,
                ThemeMode.light => Icons.light_mode,
                ThemeMode.dark => Icons.dark_mode,
              },
              color: context.primaryAccent,
            ),
            onPressed: () => _showThemeSelectionModal(context, ref),
          ),
          IconButton(
            tooltip: '운영진 사용 가이드',
            icon: Icon(Icons.help_outline, color: context.primaryAccent),
            onPressed: () => _showManualModal(context),
          ),
        ],
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

            Text(
              '단계별 진행',
              style: TextStyle(
                color: context.textPrimary,
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
            const SizedBox(height: 28),
            Center(
              child: Text(
                '${AppConstants.appName} ${AppConstants.fullVersionString}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                AppConstants.builtBy,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 10.5,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
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

  void _showThemeSelectionModal(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: context.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: context.primaryAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '화면 테마 설정',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '기본값은 안드로이드 시스템 설정에 맞추어 자동 변경됩니다.',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildThemeOptionTile(
                ctx,
                ref,
                mode: ThemeMode.system,
                title: '시스템 설정 연동 (기본값)',
                subtitle: '안드로이드 휴대폰의 다크/라이트 설정에 따라 자동 전환',
                icon: Icons.brightness_auto,
                isSelected: currentMode == ThemeMode.system,
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                ctx,
                ref,
                mode: ThemeMode.light,
                title: '일반 모드 (라이트 테마)',
                subtitle: '밝고 산뜻한 화이트 테마를 항상 유지',
                icon: Icons.light_mode,
                isSelected: currentMode == ThemeMode.light,
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                ctx,
                ref,
                mode: ThemeMode.dark,
                title: '다크 모드 (어두운 테마)',
                subtitle: '눈부심이 적은 어두운 테마를 항상 유지',
                icon: Icons.dark_mode,
                isSelected: currentMode == ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final activeColor = context.primaryAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.12)
                : context.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : context.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withOpacity(0.2)
                      : (context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : context.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? activeColor : context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: activeColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // 시트 핸들바
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF00E5FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '운영진 현장 사용 매뉴얼',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.primaryAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppConstants.versionString,
                                    style: TextStyle(
                                      color: context.primaryAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '체육관에서 빠르고 간편하게 명찰 찾기',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                Divider(color: context.dividerColor, height: 1),
                // 내용 스크롤 영역
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // 3단계 워크플로우
                      _buildManualSectionTitle(
                        icon: Icons.alt_route,
                        color: const Color(0xFF00E5FF),
                        title: '현장 3단계 워크플로우',
                      ),
                      const SizedBox(height: 10),
                      _buildWorkflowStep(
                        step: '1',
                        title: '참석자 등록',
                        desc: '카톡/밴드 투표 화면 캡처본을 올리면 이름만 자동 파싱됩니다. 누락 인원은 수동 추가 가능합니다.',
                        color: const Color(0xFF00E5FF),
                      ),
                      _buildWorkflowStep(
                        step: '2',
                        title: '매칭판 촬영',
                        desc: '체육관 보드판 전체가 화면에 들어오도록 촬영합니다. 살짝 비스듬히 찍으면 조명 반사를 피할 수 있습니다.',
                        color: const Color(0xFF00FF88),
                      ),
                      _buildWorkflowStep(
                        step: '3',
                        title: '위치 확인 & 코트 체크',
                        desc: '형광 네온 박스로 표시된 자석 명찰을 코트에 꽂고 터치하여 체크(✓)를 완료합니다.',
                        color: const Color(0xFFFFB74D),
                        isLast: true,
                      ),

                      const SizedBox(height: 20),

                      // 중요 팁 배너
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00FF88).withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, color: Color(0xFF00FF88), size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '조명 반사 해결 꿀팁!',
                                    style: TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '체육관 천장 형광등이 보드판 코팅면에 반사될 경우, 정면 대신 살짝 대각선(비스듬히)에서 촬영하면 한글 자모 퍼지 엔진이 훨씬 정확하게 찾아냅니다.',
                                    style: TextStyle(
                                      color: Color(0xFFCFD8DC),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 제스처 & 사용 팁
                      _buildManualSectionTitle(
                        icon: Icons.touch_app,
                        color: const Color(0xFFFF9100),
                        title: '결과 화면 제스처 팁',
                      ),
                      const SizedBox(height: 10),
                      _buildTipCard(
                        icon: Icons.pinch,
                        title: '두 손가락 핀치 줌',
                        desc: '결과 화면에서 두 손가락으로 자유롭게 확대/축소 및 이동하여 작은 명찰 글씨를 선명하게 확인하세요.',
                      ),
                      const SizedBox(height: 8),
                      _buildTipCard(
                        icon: Icons.check_circle_outline,
                        title: '체크(✓) 토글',
                        desc: '명찰 박스나 하단 참석자 칩을 터치하면 코트 배치 완료(회색)로 바뀌며, 다시 누르면 언제든 취소됩니다.',
                      ),
                      const SizedBox(height: 8),
                      _buildTipCard(
                        icon: Icons.percent,
                        title: '우측 상단 % 버튼',
                        desc: '한글 자모 퍼지 매칭 엔진의 유사도(예: 88%)가 궁금할 때 터치하여 박스 라벨에 표시할 수 있습니다.',
                      ),

                      const SizedBox(height: 20),

                      // 자주 묻는 질문 FAQ
                      _buildManualSectionTitle(
                        icon: Icons.help_center_outlined,
                        color: Colors.white,
                        title: '자주 묻는 질문 (FAQ)',
                      ),
                      const SizedBox(height: 10),
                      _buildFaqItem(
                        q: 'Q. 분명 보드판에 있는데 "미발견"으로 떠요.',
                        a: '조명 반사로 글자가 날아간 경우일 수 있습니다. 상단 [다시 촬영] 버튼을 눌러 각도를 살짝 변경하여 재촬영해 보세요.',
                      ),
                      _buildFaqItem(
                        q: 'Q. 카톡 캡처본에서 이상한 단어가 들어갔어요.',
                        a: '40여 개 키워드가 자동 필터링되나, 특이한 단어가 남은 경우 칩의 X 버튼을 눌러 삭제할 수 있습니다.',
                      ),
                      _buildFaqItem(
                        q: 'Q. 모임 전 미리 테스트해볼 수 있나요?',
                        a: '홈 화면 하단의 [테스트용 샘플 참석자 불러오기]를 누르면 가상 명단 8명으로 바로 연습 가능합니다.',
                      ),

                      const SizedBox(height: 20),

                      // 닫기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '확인 완료',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildManualSectionTitle({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowStep({
    required String step,
    required String title,
    required String desc,
    required Color color,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade800,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String q, required String a}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              color: Color(0xFFFFB74D),
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a,
            style: const TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
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
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled
                  ? accentColor.withOpacity(context.isDarkMode ? 0.4 : 0.6)
                  : context.cardBorder,
            ),
            boxShadow: context.isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? accentColor.withOpacity(0.15)
                      : (context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isEnabled ? accentColor : (context.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
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
                            color: isEnabled ? context.textPrimary : context.textSecondary,
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
                            ? context.textSecondary
                            : (context.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? accentColor : (context.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

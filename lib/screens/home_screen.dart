// home_screen.dart
// 메인 UI를 조립하는 화면 (Sanctuary Screen)
// - 상단: 설정 버튼 (사운드 On/Off)
// - 중앙: RoomDisplay (메인 룸 영역)
// - 중하단: TimerText (타이머 텍스트)
// - 하단: ControlButtons (시작/정지 버튼)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/timer_provider.dart';
import '../utils/constants.dart';
import '../widgets/room_display.dart';
import '../widgets/timer_text.dart';
import '../widgets/control_buttons.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer를 사용하여 TimerProvider의 상태 변화를 구독
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // 현재 모드에 따른 배경색 결정
        final backgroundColor = timerProvider.isFocusMode
            ? focusBackgroundColor
            : restBackgroundColor;

        // 현재 모드에 따른 텍스트 색상 (가독성을 위해)
        final textColor = timerProvider.isFocusMode
            ? Colors.white
            : Colors.black87;

        return Scaffold(
          // AnimatedContainer로 배경색 부드럽게 전환
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            color: backgroundColor,
            child: SafeArea(
              // 다이내믹 아일랜드와의 여백 확보
              minimum: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // 상단 추가 여백 (다이내믹 아일랜드 대응)
                  const SizedBox(height: 8),

                  // ============================================
                  // 상단 영역: 태그 배지 & 음소거 버튼
                  // ============================================
                  _buildTopBar(context, timerProvider, textColor),

                  // ============================================
                  // 중앙 영역: Room Display (메인 이미지/배경)
                  // ============================================
                  const Expanded(flex: 3, child: RoomDisplay()),

                  // ============================================
                  // 중하단 영역: 타이머 텍스트
                  // ============================================
                  const Expanded(flex: 1, child: TimerText()),

                  // ============================================
                  // 하단 영역: 컨트롤 버튼
                  // ============================================
                  const Padding(
                    padding: EdgeInsets.only(bottom: 48.0),
                    child: ControlButtons(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 상단 바 위젯
  /// - 왼쪽: 태그 배지 (탭하면 SetupScreen으로 이동)
  /// - 오른쪽: 사운드 음소거 토글 버튼
  Widget _buildTopBar(
    BuildContext context,
    TimerProvider timerProvider,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 현재 태그 배지 (탭 가능)
          _buildTagBadge(context, timerProvider, textColor),

          // ============================================
          // 음소거(Mute) 토글 버튼
          // ============================================
          _buildMuteToggleButton(timerProvider, textColor),
        ],
      ),
    );
  }

  /// 태그 배지 위젯 (탭하면 SetupScreen으로 이동)
  Widget _buildTagBadge(
    BuildContext context,
    TimerProvider timerProvider,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () {
        // SetupScreen으로 이동 (push - 수정 모드)
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SetupScreen(isEditMode: true), // 수정 모드로 이동
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 왼쪽 아이콘 - 시인성을 위해 밝은 색상 사용
            Icon(
              timerProvider.isRunning || timerProvider.isPaused
                  ? Icons.local_fire_department_rounded
                  : Icons.tag_rounded,
              color: Colors.white.withValues(alpha: 0.85), // 밝은 흰색으로 시인성 향상
              size: 18,
            ),
            const SizedBox(width: 6),
            // 텍스트
            Text(
              // Running/Paused 상태: "태그 중..." / Ready 상태: 태그 표시
              timerProvider.isRunning || timerProvider.isPaused
                  ? '${timerProvider.selectedTag} 중...'
                  : timerProvider.selectedTag,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            // 수정 아이콘 (수정 가능함을 암시) - 시인성 향상
            Padding(
              padding: const EdgeInsets.all(2), // 터치 영역 확보
              child: Icon(
                Icons.edit_rounded,
                color: Colors.white.withValues(alpha: 0.7), // 살짝 연한 흰색
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 음소거 토글 버튼 위젯
  Widget _buildMuteToggleButton(TimerProvider timerProvider, Color textColor) {
    // 음소거 상태에 따른 아이콘 결정
    final isMuted = timerProvider.isMuted;
    final icon = isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 음소거 토글
          timerProvider.toggleMute();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: textColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              icon,
              key: ValueKey(isMuted),
              color: isMuted
                  ? textColor.withValues(alpha: 0.4) // 음소거 시 흐리게
                  : textColor, // 정상 상태
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

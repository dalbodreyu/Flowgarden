// control_buttons.dart
// 시작/정지/포기 버튼 위젯
// - 타이머 상태(Running, Paused, Ready)에 따라 버튼이 변경됨
// - Running 상태: Pause 아이콘 + 하단에 '포기하기' 텍스트 버튼
// - Paused 상태: Resume 아이콘 + 왼쪽에 포기하기/건너뛰기 버튼
// - Ready 상태: Play 아이콘만 표시

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/timer_provider.dart';
import '../utils/constants.dart';

class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    // TimerProvider 구독
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // 모드에 따른 색상 설정
        final primaryColor =
            timerProvider.isFocusMode ? focusPrimaryColor : restPrimaryColor;

        final textColor =
            timerProvider.isFocusMode ? Colors.white : Colors.black87;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ============================================
              // 버튼 Row (Paused 상태일 때만 포기하기 아이콘 버튼 왼쪽에 표시)
              // ============================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Paused 상태일 때만 왼쪽에 포기하기/건너뛰기 아이콘 버튼 표시
                  if (timerProvider.isPaused) ...[
                    _buildGiveUpIconButton(timerProvider, textColor),
                const SizedBox(width: 24),
              ],

              // ============================================
              // 메인 버튼 (상태에 따라 변경)
              // Ready -> Play 버튼
              // Running -> Pause 버튼
              // Paused -> Resume(Play) 버튼
              // ============================================
              _buildMainButton(timerProvider, primaryColor),
                ],
              ),

              // ============================================
              // Running 상태일 때만 하단에 '포기하기' 텍스트 버튼 표시
              // ============================================
              if (timerProvider.isRunning) ...[
                const SizedBox(height: 16),
                _buildGiveUpTextButton(timerProvider, textColor),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 메인 액션 버튼 (Play / Pause / Resume) + 원형 프로그레스
  Widget _buildMainButton(TimerProvider provider, Color primaryColor) {
    // 상태에 따른 아이콘과 동작 결정
    IconData buttonIcon;
    VoidCallback onPressed;
    String tooltip;

    if (provider.isReady) {
      // Ready 상태 -> 재생 버튼 (Start)
      buttonIcon = Icons.play_arrow_rounded;
      onPressed = provider.start;
      tooltip = 'Start';
    } else if (provider.isRunning) {
      // Running 상태 -> 일시정지 버튼 (Pause)
      buttonIcon = Icons.pause_rounded;
      onPressed = provider.pause;
      tooltip = 'Pause';
    } else {
      // Paused 상태 -> 재생 버튼 (Resume)
      buttonIcon = Icons.play_arrow_rounded;
      onPressed = provider.resume;
      tooltip = 'Resume';
    }

    // 프로그레스 표시 여부 (Running 또는 Paused 상태)
    final showProgress = provider.isRunning || provider.isPaused;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Stack으로 감싸서 원형 프로그레스를 버튼 뒤에 배치
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ============================================
          // 원형 프로그레스 (버튼보다 약간 큰 사이즈)
          // ============================================
          if (showProgress)
            SizedBox(
              width: 96, // 버튼(80) + 여백(16)
              height: 96,
              child: CircularProgressIndicator(
                // 진행률: 시간이 갈수록 차오름 (0.0 -> 1.0)
                value: provider.progress,
                strokeWidth: 5,
                // 프로그레스 색상: 버튼 색상과 같은 계열의 반투명
                color: primaryColor.withValues(alpha: 0.8),
                // 배경색: 아주 연한 회색
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                // 끝부분 둥글게
                strokeCap: StrokeCap.round,
              ),
            ),

          // ============================================
          // 메인 버튼
          // ============================================
          Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              // 레트로 게임 스타일의 두꺼운 테두리
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
              // 입체감을 주는 그림자
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Tooltip(
              message: tooltip,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  buttonIcon,
                  key: ValueKey(buttonIcon),
                  size: 40,
                  color: Colors.white,
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

  /// 포기하기 / 건너뛰기 아이콘 버튼 (Paused 상태에서 표시)
  Widget _buildGiveUpIconButton(TimerProvider provider, Color textColor) {
    // 모드에 따른 버튼 동작 결정
    // 집중 모드: Give up (포기하기)
    // 휴식 모드: Skip (건너뛰기)
    final isFocus = provider.isFocusMode;
    final buttonIcon = isFocus ? Icons.close_rounded : Icons.skip_next_rounded;
    final tooltip = isFocus ? 'Give up' : 'Skip';
    final onPressed = isFocus ? provider.giveUp : provider.skipRest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: textColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              buttonIcon,
              size: 28,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  /// 포기하기 텍스트 버튼 (Running 상태에서 하단에 표시)
  Widget _buildGiveUpTextButton(TimerProvider provider, Color textColor) {
    // 집중 모드: 포기하기 / 휴식 모드: 건너뛰기
    final isFocus = provider.isFocusMode;
    final buttonText = isFocus ? '포기하기' : '건너뛰기';
    final onPressed = isFocus ? provider.giveUp : provider.skipRest;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.close_rounded,
          size: 16,
          color: textColor.withValues(alpha: 0.5),
        ),
        label: Text(
          buttonText,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

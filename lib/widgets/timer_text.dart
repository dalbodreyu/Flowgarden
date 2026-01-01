// timer_text.dart
// 타이머 텍스트 위젯 (예: 25:00 형식으로 표시)
// - Google Fonts의 Silkscreen 폰트 사용 (레트로 픽셀 스타일)
// - TimerProvider에서 formattedTime을 받아 큼지막하게 표시

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/timer_provider.dart';
import '../utils/constants.dart';

class TimerText extends StatelessWidget {
  const TimerText({super.key});

  @override
  Widget build(BuildContext context) {
    // TimerProvider 구독
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // 모드에 따른 텍스트 색상
        final textColor =
            timerProvider.isFocusMode ? Colors.white : Colors.black87;

        final accentColor =
            timerProvider.isFocusMode ? focusPrimaryColor : restPrimaryColor;

        return Center(
          // FittedBox로 감싸서 공간에 맞게 자동 축소
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              // mainAxisSize.min으로 최소 크기만 차지
              mainAxisSize: MainAxisSize.min,
              children: [
                // ============================================
                // 메인 타이머 텍스트 (Silkscreen 폰트)
                // ============================================
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: _getTimerTextStyle(textColor, accentColor),
                  child: Text(timerProvider.formattedTime),
                ),

                const SizedBox(height: 8),

                // ============================================
                // 현재 상태 표시 배지
                // ============================================
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(timerProvider.timerState),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(timerProvider),
                      style: GoogleFonts.silkscreen(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  /// Silkscreen 폰트를 사용한 타이머 텍스트 스타일
  /// - 폰트 로드 실패 시 기본 Monospace 폰트 사용
  TextStyle _getTimerTextStyle(Color textColor, Color accentColor) {
    return GoogleFonts.silkscreen(
      fontSize: 72, // 큼지막하게 표시 (FittedBox가 자동 조절)
      fontWeight: FontWeight.w400,
      color: textColor,
      letterSpacing: 6, // 글자 간격 넓게
      shadows: [
        // 레트로 픽셀 느낌의 그림자 효과
        Shadow(
          color: accentColor.withValues(alpha: 0.6),
          blurRadius: 0,
          offset: const Offset(3, 3), // 픽셀 그림자
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
      ],
    );
  }

  /// 현재 상태에 따른 텍스트 반환
  String _getStatusText(TimerProvider provider) {
    if (provider.isReady) {
      return provider.isFocusMode ? 'READY TO FOCUS' : 'TIME TO REST';
    } else if (provider.isRunning) {
      return provider.isFocusMode ? 'FOCUSING...' : 'RESTING...';
    } else if (provider.isPaused) {
      return 'PAUSED';
    }
    return '';
  }
}

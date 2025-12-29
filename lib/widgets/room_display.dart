// room_display.dart
// 중앙 동영상 표시 위젯 (집중/휴식 모드에 따라 테마 변경)
// - VideoPlayer를 사용하여 동영상 배경 재생
// - 집중 모드: video_focus.mp4
// - 휴식 모드: video_rest.mp4
// - 크기: 300x300, 둥근 모서리 (기존 디자인 유지)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/timer_provider.dart';
import '../utils/constants.dart';

class RoomDisplay extends StatefulWidget {
  const RoomDisplay({super.key});

  @override
  State<RoomDisplay> createState() => _RoomDisplayState();
}

class _RoomDisplayState extends State<RoomDisplay> {
  // 집중 모드 비디오 컨트롤러
  VideoPlayerController? _focusVideoController;
  // 휴식 모드 비디오 컨트롤러
  VideoPlayerController? _restVideoController;

  // 비디오 초기화 완료 여부
  bool _isFocusVideoInitialized = false;
  bool _isRestVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  /// 비디오 컨트롤러 초기화
  Future<void> _initializeVideos() async {
    // 집중 모드 비디오 초기화
    _focusVideoController = VideoPlayerController.asset(
      'assets/videos/video_focus.mp4',
    );

    // 휴식 모드 비디오 초기화
    _restVideoController = VideoPlayerController.asset(
      'assets/videos/video_rest.mp4',
    );

    try {
      // 병렬로 초기화
      await Future.wait([
        _focusVideoController!.initialize().then((_) {
          _focusVideoController!.setLooping(true); // 무한 반복
          _focusVideoController!.setVolume(0); // 음소거
          _focusVideoController!.play(); // 자동 재생
          if (mounted) {
            setState(() {
              _isFocusVideoInitialized = true;
            });
          }
        }),
        _restVideoController!.initialize().then((_) {
          _restVideoController!.setLooping(true); // 무한 반복
          _restVideoController!.setVolume(0); // 음소거
          // 휴식 모드 비디오는 일단 일시정지
          if (mounted) {
            setState(() {
              _isRestVideoInitialized = true;
            });
          }
        }),
      ]);
    } catch (e) {
      // 비디오 로드 실패 시 폴백 UI 표시
      debugPrint('비디오 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    _focusVideoController?.dispose();
    _restVideoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TimerProvider 구독
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // 모드에 따른 색상 설정 (그림자, 테두리용)
        final primaryColor =
            timerProvider.isFocusMode ? focusPrimaryColor : restPrimaryColor;

        // 모드에 따른 비디오 컨트롤러 및 초기화 상태
        final videoController = timerProvider.isFocusMode
            ? _focusVideoController
            : _restVideoController;
        final isVideoInitialized = timerProvider.isFocusMode
            ? _isFocusVideoInitialized
            : _isRestVideoInitialized;

        // 모드 전환 시 비디오 재생/일시정지 처리
        _handleVideoPlayback(timerProvider.isFocusMode);

        return Center(
          child: Container(
            // ============================================
            // 크기: 300x300 (기존 디자인 유지)
            // ============================================
            width: 300,
            height: 300,

            // ============================================
            // 스타일링: 둥근 모서리, 테두리, 그림자
            // ============================================
            decoration: BoxDecoration(
              // 둥근 모서리 (24px)
              borderRadius: BorderRadius.circular(24),
              // 레트로 스타일 테두리
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 4,
              ),
              // 부드러운 그림자 효과
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            // ============================================
            // 비디오 영역: ClipRRect로 둥근 모서리 적용
            // ============================================
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), // 테두리 안쪽이므로 약간 작게
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ============================================
                  // 비디오 또는 폴백 UI
                  // ============================================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: isVideoInitialized && videoController != null
                        ? _buildVideoPlayer(
                            videoController,
                            timerProvider.isFocusMode,
                          )
                        : _buildLoadingOrFallback(timerProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 모드 전환 시 비디오 재생/일시정지 처리
  void _handleVideoPlayback(bool isFocusMode) {
    if (isFocusMode) {
      // 집중 모드: 집중 비디오 재생, 휴식 비디오 일시정지
      _focusVideoController?.play();
      _restVideoController?.pause();
    } else {
      // 휴식 모드: 휴식 비디오 재생, 집중 비디오 일시정지
      _restVideoController?.play();
      _focusVideoController?.pause();
    }
  }

  /// 비디오 플레이어 위젯
  Widget _buildVideoPlayer(VideoPlayerController controller, bool isFocusMode) {
    return SizedBox.expand(
      key: ValueKey(isFocusMode ? 'focus' : 'rest'),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  /// 로딩 또는 폴백 UI
  Widget _buildLoadingOrFallback(TimerProvider timerProvider) {
    final primaryColor =
        timerProvider.isFocusMode ? focusPrimaryColor : restPrimaryColor;
    final secondaryColor =
        timerProvider.isFocusMode ? focusSecondaryColor : restSecondaryColor;

    return AnimatedContainer(
      key: ValueKey('fallback_${timerProvider.isFocusMode}'),
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로딩 인디케이터 또는 모드 아이콘
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.8),
            ),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          // 모드 텍스트
          Text(
            timerProvider.isFocusMode ? '🌙 FOCUS' : '☀️ REST',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

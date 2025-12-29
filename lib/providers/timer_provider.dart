// timer_provider.dart
// 타이머 로직과 상태 관리를 담당하는 Provider
// - 25분 집중 / 5분 휴식 사이클 관리
// - Start, Pause, Resume, Reset, Give up 기능
// - 집중 완료 시 로컬에 횟수 저장
// - 배경음악 재생/정지 (집중 모드 Running일 때만 재생)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/constants.dart';

// ============================================================
// 타이머 상태 열거형
// ============================================================
/// 타이머의 현재 동작 상태
enum TimerState {
  ready, // 초기 상태 - 시작 대기 중
  running, // 카운트다운 진행 중
  paused, // 일시 정지 상태
}

/// 타이머 모드 (집중 or 휴식)
enum TimerMode {
  focus, // 집중 모드 (25분)
  rest, // 휴식 모드 (5분)
}

// ============================================================
// SharedPreferences 키 상수
// ============================================================
const String _keyPomodoroCount = 'pomodoro_count';
const String _keyLastDate = 'last_date';
const String _keyIsMuted = 'is_muted';

// ============================================================
// TimerProvider 클래스
// ============================================================
class TimerProvider extends ChangeNotifier {
  // ----------------------------------------------------------
  // 내부 상태 변수
  // ----------------------------------------------------------
  TimerState _timerState = TimerState.ready; // 현재 타이머 상태
  TimerMode _timerMode = TimerMode.focus; // 현재 모드 (집중/휴식)

  int _remainingSeconds = focusDurationMinutes * 60; // 남은 시간 (초)
  int _pomodoroCount = 0; // 오늘 완료한 뽀모도로 횟수

  Timer? _timer; // 카운트다운 타이머
  SharedPreferences? _prefs; // 로컬 저장소

  // ----------------------------------------------------------
  // SetupScreen에서 설정한 값
  // ----------------------------------------------------------
  int _selectedTime = 25; // 사용자가 선택한 집중 시간 (분)
  String _selectedTag = '집중'; // 사용자가 선택한 태그

  // ----------------------------------------------------------
  // 오디오 관련 변수
  // ----------------------------------------------------------
  final AudioPlayer _audioPlayer = AudioPlayer(); // 배경음악 플레이어
  bool _isMuted = false; // 음소거 상태
  bool _isAudioInitialized = false; // 오디오 초기화 완료 여부

  // ----------------------------------------------------------
  // 알림 관련 변수
  // ----------------------------------------------------------
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin(); // 로컬 알림 플러그인
  bool _isNotificationInitialized = false; // 알림 초기화 완료 여부

  // ----------------------------------------------------------
  // Getter - UI에서 상태를 읽기 위한 접근자
  // ----------------------------------------------------------

  /// 현재 타이머 상태 (ready, running, paused)
  TimerState get timerState => _timerState;

  /// 현재 타이머 모드 (focus, rest)
  TimerMode get timerMode => _timerMode;

  /// 남은 시간 (초 단위)
  int get remainingSeconds => _remainingSeconds;

  /// 남은 분
  int get remainingMinutes => _remainingSeconds ~/ 60;

  /// 남은 초 (분 제외한 나머지)
  int get remainingSecondsInMinute => _remainingSeconds % 60;

  /// "MM:SS" 형식의 시간 문자열
  String get formattedTime {
    final minutes = remainingMinutes.toString().padLeft(2, '0');
    final seconds = remainingSecondsInMinute.toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 오늘 완료한 뽀모도로 횟수
  int get pomodoroCount => _pomodoroCount;

  /// 현재 집중 모드인지 여부
  bool get isFocusMode => _timerMode == TimerMode.focus;

  /// 현재 휴식 모드인지 여부
  bool get isRestMode => _timerMode == TimerMode.rest;

  /// 타이머가 실행 중인지 여부
  bool get isRunning => _timerState == TimerState.running;

  /// 타이머가 일시 정지 상태인지 여부
  bool get isPaused => _timerState == TimerState.paused;

  /// 타이머가 대기 상태인지 여부
  bool get isReady => _timerState == TimerState.ready;

  /// 전체 시간 대비 진행률 (0.0 ~ 1.0)
  double get progress {
    // 집중 모드는 selectedTime 사용, 휴식 모드는 고정값 사용
    final totalSeconds = isFocusMode
        ? _selectedTime * 60
        : restDurationMinutes * 60;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }

  /// 음소거 상태
  bool get isMuted => _isMuted;

  /// 사용자가 선택한 집중 시간 (분)
  int get selectedTime => _selectedTime;

  /// 사용자가 선택한 태그
  String get selectedTag => _selectedTag;

  // ----------------------------------------------------------
  // SetupScreen 설정 메서드
  // ----------------------------------------------------------

  /// 집중 시간 설정 (분 단위)
  void setTime(int minutes) {
    _selectedTime = minutes;
    // 집중 모드 초기 시간도 업데이트
    if (_timerMode == TimerMode.focus && _timerState == TimerState.ready) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }

  /// 태그 설정
  void setTag(String tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // 생성자 및 초기화
  // ----------------------------------------------------------
  TimerProvider() {
    _initPreferences();
    _initAudio();
    _initNotifications();
  }

  /// SharedPreferences 초기화 및 저장된 데이터 로드
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPomodoroCount();
    _loadMuteState();
  }

  /// 오디오 플레이어 초기화
  Future<void> _initAudio() async {
    try {
      // 오디오 플레이어 설정
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // 반복 재생
      await _audioPlayer.setVolume(0.5); // 볼륨 50%
      _isAudioInitialized = true;
    } catch (e) {
      // 오디오 초기화 실패 시 에러 무시
      debugPrint('오디오 초기화 실패: $e');
      _isAudioInitialized = false;
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initNotifications() async {
    try {
      // Android 알림 채널 설정
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher', // 앱 아이콘 사용
      );

      // iOS/macOS 알림 설정
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // main.dart에서 별도로 요청
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // 통합 초기화 설정
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      // 플러그인 초기화
      await _notificationsPlugin.initialize(initSettings);
      _isNotificationInitialized = true;
    } catch (e) {
      debugPrint('알림 초기화 실패: $e');
      _isNotificationInitialized = false;
    }
  }

  /// 알림 표시 (타이머 완료 시 호출)
  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    if (!_isNotificationInitialized) return;

    try {
      // Android 알림 상세 설정
      const androidDetails = AndroidNotificationDetails(
        'flow_garden_timer', // 채널 ID
        'Timer Notifications', // 채널 이름
        channelDescription: '타이머 완료 알림', // 채널 설명
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      // iOS/macOS 알림 상세 설정
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // 통합 알림 상세 설정
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // 알림 표시
      await _notificationsPlugin.show(
        0, // 알림 ID
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('알림 표시 실패: $e');
    }
  }

  /// 저장된 뽀모도로 횟수 불러오기
  /// - 날짜가 바뀌면 카운트 초기화
  void _loadPomodoroCount() {
    if (_prefs == null) return;

    final today = _getTodayString();
    final savedDate = _prefs!.getString(_keyLastDate) ?? '';

    if (savedDate == today) {
      // 오늘 저장된 데이터가 있으면 불러오기
      _pomodoroCount = _prefs!.getInt(_keyPomodoroCount) ?? 0;
    } else {
      // 날짜가 바뀌었으면 카운트 초기화
      _pomodoroCount = 0;
      _savePomodoroCount();
    }
    notifyListeners();
  }

  /// 저장된 음소거 상태 불러오기
  void _loadMuteState() {
    if (_prefs == null) return;
    _isMuted = _prefs!.getBool(_keyIsMuted) ?? false;
    notifyListeners();
  }

  /// 뽀모도로 횟수를 로컬에 저장
  Future<void> _savePomodoroCount() async {
    if (_prefs == null) return;

    await _prefs!.setInt(_keyPomodoroCount, _pomodoroCount);
    await _prefs!.setString(_keyLastDate, _getTodayString());
  }

  /// 음소거 상태를 로컬에 저장
  Future<void> _saveMuteState() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_keyIsMuted, _isMuted);
  }

  /// 오늘 날짜를 "YYYY-MM-DD" 형식 문자열로 반환
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ----------------------------------------------------------
  // 오디오 컨트롤 메서드
  // ----------------------------------------------------------

  /// 음소거 토글
  void toggleMute() {
    _isMuted = !_isMuted;
    _saveMuteState();

    // 현재 재생 중이면 음소거 상태에 따라 처리
    if (_isMuted) {
      _stopAudio();
    } else if (_shouldPlayAudio()) {
      _playAudio();
    }

    notifyListeners();
  }

  /// 배경음악을 재생해야 하는 조건 확인
  /// - 집중 모드 + Running 상태 + 음소거 아님
  bool _shouldPlayAudio() {
    return isFocusMode && isRunning && !_isMuted;
  }

  /// 배경음악 재생
  Future<void> _playAudio() async {
    if (!_isAudioInitialized || _isMuted) return;

    try {
      // Asset 파일에서 오디오 재생
      await _audioPlayer.play(AssetSource('sounds/lofi_beat.mp3'));
    } catch (e) {
      // 오디오 파일이 없거나 재생 실패 시 에러 무시
      debugPrint('배경음악 재생 실패: $e');
    }
  }

  /// 배경음악 정지
  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // 정지 실패 시 에러 무시
      debugPrint('배경음악 정지 실패: $e');
    }
  }

  /// 배경음악 일시 정지
  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('배경음악 일시정지 실패: $e');
    }
  }

  /// 배경음악 재개
  Future<void> _resumeAudio() async {
    if (!_isAudioInitialized || _isMuted) return;

    try {
      await _audioPlayer.resume();
    } catch (e) {
      // resume 실패 시 처음부터 재생
      _playAudio();
    }
  }

  // ----------------------------------------------------------
  // Wakelock 컨트롤 메서드 (화면 꺼짐 방지)
  // ----------------------------------------------------------

  /// 화면 꺼짐 방지 활성화
  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      debugPrint('Wakelock 활성화됨');
    } catch (e) {
      debugPrint('Wakelock 활성화 실패: $e');
    }
  }

  /// 화면 꺼짐 방지 비활성화
  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      debugPrint('Wakelock 비활성화됨');
    } catch (e) {
      debugPrint('Wakelock 비활성화 실패: $e');
    }
  }

  // ----------------------------------------------------------
  // 타이머 컨트롤 메서드
  // ----------------------------------------------------------

  /// 타이머 시작
  /// - Ready 또는 Paused 상태에서 호출 가능
  void start() {
    if (_timerState == TimerState.running) return;

    final wasPaused = _timerState == TimerState.paused;
    _timerState = TimerState.running;
    notifyListeners();

    // 화면 꺼짐 방지 활성화 (타이머 진행 중에는 화면 유지)
    _enableWakelock();

    // 1초마다 카운트다운
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });

    // 집중 모드일 때만 배경음악 재생
    if (isFocusMode && !_isMuted) {
      if (wasPaused) {
        _resumeAudio();
      } else {
        _playAudio();
      }
    }
  }

  /// 타이머 일시 정지
  void pause() {
    if (_timerState != TimerState.running) return;

    _timer?.cancel();
    _timerState = TimerState.paused;

    // 화면 꺼짐 방지 비활성화 (일시 정지 중에는 화면 꺼짐 허용)
    _disableWakelock();

    // 배경음악 일시 정지
    _pauseAudio();

    notifyListeners();
  }

  /// 일시 정지 후 재개 (start와 동일한 동작)
  void resume() {
    start();
  }

  /// 타이머 리셋 (현재 모드의 초기 시간으로)
  void reset() {
    _timer?.cancel();
    _timerState = TimerState.ready;
    // 집중 모드는 selectedTime 사용
    _remainingSeconds = isFocusMode
        ? _selectedTime * 60
        : restDurationMinutes * 60;

    // 화면 꺼짐 방지 비활성화
    _disableWakelock();

    // 배경음악 정지
    _stopAudio();

    notifyListeners();
  }

  /// 포기하기 (집중 모드에서만 사용)
  /// - 타이머를 초기화하고 기록하지 않음
  void giveUp() {
    _timer?.cancel();
    _timerState = TimerState.ready;
    _timerMode = TimerMode.focus;
    // selectedTime 사용
    _remainingSeconds = _selectedTime * 60;

    // 화면 꺼짐 방지 비활성화
    _disableWakelock();

    // 배경음악 정지
    _stopAudio();

    notifyListeners();
  }

  /// 휴식 건너뛰기
  /// - 휴식 모드에서 바로 다음 집중 모드로 전환
  void skipRest() {
    if (_timerMode != TimerMode.rest) return;

    _timer?.cancel();
    _switchToFocusMode();
  }

  // ----------------------------------------------------------
  // 내부 로직 메서드
  // ----------------------------------------------------------

  /// 매 초마다 호출되는 틱 함수
  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      // 타이머 종료 처리
      _onTimerComplete();
    }
  }

  /// 타이머 완료 시 처리
  void _onTimerComplete() {
    _timer?.cancel();

    // 화면 꺼짐 방지 비활성화
    _disableWakelock();

    // 배경음악 정지
    _stopAudio();

    if (_timerMode == TimerMode.focus) {
      // 집중 모드 완료 -> 횟수 증가 및 저장, 휴식 모드로 전환
      _pomodoroCount++;
      _savePomodoroCount();

      // 백그라운드 알림 표시 (집중 완료)
      _showNotification(
        title: '🌿 FlowGarden',
        body: '집중 시간이 끝났습니다! 휴식을 취하세요.',
      );

      _switchToRestMode();
    } else {
      // 휴식 모드 완료 -> 집중 모드로 전환
      // 백그라운드 알림 표시 (휴식 완료)
      _showNotification(
        title: '🌿 FlowGarden',
        body: '휴식이 끝났습니다! 다시 집중할 준비가 되셨나요?',
      );

      _switchToFocusMode();
    }
  }

  /// 휴식 모드로 전환
  void _switchToRestMode() {
    _timerMode = TimerMode.rest;
    _timerState = TimerState.ready;
    _remainingSeconds = restDurationMinutes * 60;
    notifyListeners();
  }

  /// 집중 모드로 전환
  void _switchToFocusMode() {
    _timerMode = TimerMode.focus;
    _timerState = TimerState.ready;
    // selectedTime 사용
    _remainingSeconds = _selectedTime * 60;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // 리소스 정리
  // ----------------------------------------------------------

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose(); // 오디오 플레이어 해제
    super.dispose();
  }
}

// main.dart
// FlowGarden 앱 진입점
// 테마 설정 및 Provider 초기화
// iOS 알림 권한 요청 포함

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/timer_provider.dart';
import 'screens/setup_screen.dart';

/// 로컬 알림 플러그인 인스턴스 (권한 요청용)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  // Flutter 바인딩 초기화 (비동기 작업 전 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 알림 플러그인 초기화 및 권한 요청
  await _initializeNotifications();

  runApp(const FlowGardenApp());
}

/// 알림 플러그인 초기화 및 권한 요청
Future<void> _initializeNotifications() async {
  // Android 알림 채널 설정
  const androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher', // 앱 아이콘 사용
  );

  // iOS/macOS 알림 설정 (초기화 시 권한 요청 포함)
  const darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: true, // 초기화 시 권한 요청
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // 통합 초기화 설정
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
    macOS: darwinSettings,
  );

  // 플러그인 초기화 (iOS/macOS는 여기서 자동으로 권한 요청됨)
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Android 13+ (API 33+) 알림 권한 요청
  if (Platform.isAndroid) {
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }
}

class FlowGardenApp extends StatelessWidget {
  const FlowGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider를 사용하여 여러 Provider를 등록할 수 있도록 설정
    // 현재는 TimerProvider만 있지만, 추후 다른 Provider 추가 시 확장 가능
    return MultiProvider(
      providers: [
        // TimerProvider를 앱 전역에서 사용할 수 있도록 등록
        ChangeNotifierProvider(
          create: (_) => TimerProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'FlowGarden',
        // 디버그 배너 제거
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
        ),
        // SetupScreen을 시작 화면으로 설정
        home: const SetupScreen(),
      ),
    );
  }
}

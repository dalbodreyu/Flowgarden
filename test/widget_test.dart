// FlowGarden 위젯 테스트
//
// 앱의 기본 구조가 정상적으로 빌드되는지 확인하는 스모크 테스트입니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flow_garden/providers/timer_provider.dart';
import 'package:flow_garden/screens/setup_screen.dart';

void main() {
  testWidgets('FlowGarden app smoke test - SetupScreen loads', (
    WidgetTester tester,
  ) async {
    // TimerProvider와 함께 SetupScreen을 빌드
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TimerProvider(),
        child: const MaterialApp(home: SetupScreen()),
      ),
    );

    // SetupScreen의 타이틀이 표시되는지 확인
    expect(find.text('오늘의 몰입 준비'), findsOneWidget);

    // 시간 선택 칩들이 표시되는지 확인
    expect(find.text('5분'), findsOneWidget);
    expect(find.text('25분'), findsOneWidget);

    // 입장하기 버튼이 표시되는지 확인
    expect(find.text('입장하기'), findsOneWidget);
  });

  testWidgets('Tag chips are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TimerProvider(),
        child: const MaterialApp(home: SetupScreen()),
      ),
    );

    // ChoiceChip 위젯들이 표시되는지 확인
    expect(find.byType(ChoiceChip), findsAtLeast(3));

    // 업무, 독서 칩이 표시되는지 확인 (공부는 TextField에도 있어서 제외)
    expect(find.text('업무'), findsOneWidget);
    expect(find.text('독서'), findsOneWidget);
  });
}

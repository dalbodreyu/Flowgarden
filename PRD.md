PRD.md: FlowGarden (MVP Version)

1. 프로젝트 개요
   프로젝트명: FlowGarden (플로우가든)

목표: 사용자가 힐링하며 집중할 수 있는 'Cozy(아늑한)' 감성의 뽀모도로 타이머 앱 개발.

핵심 가치: 딱딱한 타이머가 아닌, 시각적(Pixel Art) 및 청각적(Lofi) 만족감을 주는 디지털 안식처 제공.

개발 범위: MVP (Minimum Viable Product) - 서버 없음, 로컬 데이터 저장, 핵심 타이머 기능만 구현.

2. 기술 스택 (Tech Stack)
   Framework: Flutter (Latest Stable)

Language: Dart

State Management: Provider (가장 직관적이고 가벼운 상태 관리)

Local Storage: shared_preferences (집중 기록 저장용)

Audio: audioplayers (배경음악 재생)

Fonts: google_fonts (Silkscreen 또는 레트로 픽셀 폰트 사용)

3. 디자인 컨셉 (Design & Assets)
   테마: 2D Isometric Pixel Art (2.5D 도트 그래픽).

컬러 팔레트:

Focus Mode (집중): 차분한 밤/비 오는 분위기 (Deep Blue, Indigo)

Rest Mode (휴식): 따뜻한 낮/햇살 분위기 (Warm Orange, Soft Yellow)

UI 스타일: 레트로 게임 UI (두꺼운 테두리, 픽셀 아이콘).

4. 핵심 기능 명세 (Functional Requirements)
   4.1. 메인 화면 (Sanctuary Screen)
   구조:

상단: 설정 버튼 (사운드 On/Off).

중앙: 현재 상태(집중/휴식)에 따라 이미지가 바뀌는 '메인 룸(Room)' 영역.

중하단: 디지털 타이머 텍스트 (예: 25:00).

하단: 메인 액션 버튼 (Start / Pause / Give up).

4.2. 타이머 로직 (Timer Logic)
기본 설정: 집중 25분 / 휴식 5분 (고정).

상태 흐름:

Ready: 초기 상태. 타이머 25:00. 버튼 [Start].

Running (Focus): 카운트다운 진행. 배경음악 재생. 버튼 [Pause].

Paused: 일시 정지 상태. 버튼 [Resume].

Completed (Focus): 25분 종료 시 알림음. 휴식 모드로 자동 전환 대기.

Running (Rest): 5분 휴식 카운트다운. 테마 변경(Warm). 버튼 [Skip].

포기하기: 집중 도중 [Give up] 버튼을 누르면 타이머가 초기화되고 기록되지 않음.

4.3. 배경음악 (Lofi Audio)
타이머가 Running (Focus) 상태일 때만 Lofi 비트가 반복 재생됨.

상단 토글 버튼으로 음소거(Mute) 가능.

앱이 백그라운드로 내려가도 타이머와 음악은 유지되어야 함.

4.4. 데이터 저장 (Local Storage)
사용자가 '집중 모드'를 완료한 횟수(Pomodoro Count)를 로컬에 저장.

앱을 껐다 켜도 "오늘의 집중 횟수: N회"가 유지되어 화면 구석에 표시됨.

5. 프로젝트 구조 (Directory Structure)
   Cursor가 코드를 작성할 때 이 구조를 따르도록 제안함.

lib/
├── main.dart # 앱 진입점, 테마 설정
├── providers/
│ └── timer_provider.dart # 타이머 로직, 상태 관리 (핵심)
├── screens/
│ └── home_screen.dart # 메인 UI 조립
├── widgets/
│ ├── room_display.dart # 중앙 이미지 표시 위젯 (애니메이션 포함)
│ ├── timer_text.dart # 타이머 텍스트 위젯
│ └── control_buttons.dart # 시작/정지 버튼 위젯
└── utils/
└── constants.dart # 컬러, 시간 설정 값 등 상수 관리

6. AI(Cursor)를 위한 개발 가이드라인
   Step-by-Step: 한 번에 모든 코드를 짜지 말고, Provider 세팅 -> UI 구현 -> Logic 연결 순서로 진행한다.

Null Safety: 모든 코드는 Null Safety를 엄격하게 준수한다.

Placeholder: 실제 이미지 자산(assets/images/)이 없으므로, 초기에는 Container에 색상(Colors.indigo 등)을 넣어 영역을 잡아준다. 추후 이미지를 넣기 쉬운 구조로 짠다.

Simplification: 복잡한 애니메이션보다는 AnimatedContainer 등을 활용해 간단한 색상/투명도 변화로 효과를 준다.

// setup_screen.dart
// 진입 화면 (SetupScreen)
// - 태그 선택 (ChoiceChip + TextField)
// - 시간 선택 (5분, 10분, 15분, 25분)
// - 입장하기 버튼

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/timer_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  /// HomeScreen에서 수정하러 온 경우 true
  final bool isEditMode;

  const SetupScreen({super.key, this.isEditMode = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // 사전 정의된 태그 목록
  final List<String> _predefinedTags = ['공부', '업무', '독서'];

  // 사전 정의된 시간 옵션 (분)
  final List<int> _timeOptions = [5, 10, 15, 25];

  // 선택된 태그 인덱스 (-1이면 직접 입력)
  int _selectedTagIndex = 0;

  // 선택된 시간 (기본 25분)
  int _selectedTime = 25;

  // 태그 입력 컨트롤러
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 수정 모드인 경우 기존 Provider 값 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingValues();
    });
  }

  /// 기존 Provider 값 불러오기
  void _loadExistingValues() {
    if (!widget.isEditMode) {
      // 처음 진입: 기본값 사용
      _tagController.text = _predefinedTags[0];
      return;
    }

    // 수정 모드: Provider에서 기존 값 불러오기
    final timerProvider = context.read<TimerProvider>();
    final existingTag = timerProvider.selectedTag;
    final existingTime = timerProvider.selectedTime;

    setState(() {
      // 태그 설정
      _tagController.text = existingTag;
      final tagIndex = _predefinedTags.indexOf(existingTag);
      _selectedTagIndex = tagIndex; // -1이면 직접 입력

      // 시간 설정
      if (_timeOptions.contains(existingTime)) {
        _selectedTime = existingTime;
      }
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 다크 테마 배경 (HomeScreen과 동일)
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 그라데이션 배경
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              focusBackgroundColor,
              focusBackgroundColor.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.only(top: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ============================================
                // 타이틀: "오늘의 몰입 준비"
                // ============================================
                Text(
                  '오늘의 몰입 준비',
                  style: GoogleFonts.silkscreen(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '무엇에 집중하시겠어요?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 48),

                // ============================================
                // 태그 선택 섹션
                // ============================================
                _buildSectionTitle('태그 선택'),
                const SizedBox(height: 16),
                _buildTagChips(),
                const SizedBox(height: 16),
                _buildTagTextField(),

                const SizedBox(height: 40),

                // ============================================
                // 시간 선택 섹션
                // ============================================
                _buildSectionTitle('집중 시간'),
                const SizedBox(height: 16),
                _buildTimeChips(),

                const SizedBox(height: 60),

                // ============================================
                // 입장하기 버튼
                // ============================================
                _buildEnterButton(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 섹션 타이틀 위젯
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.silkscreen(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.8),
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// 태그 ChoiceChip 목록
  Widget _buildTagChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_predefinedTags.length, (index) {
        final isSelected = _selectedTagIndex == index;

        return ChoiceChip(
          label: Text(_predefinedTags[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTagIndex = index;
              _tagController.text = _predefinedTags[index];
            });
          },
          // 스타일링
          selectedColor: focusPrimaryColor,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: isSelected
                  ? focusPrimaryColor
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
      }),
    );
  }

  /// 태그 직접 입력 TextField
  Widget _buildTagTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _tagController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        // 커서 색상
        cursorColor: focusPrimaryColor,
        decoration: InputDecoration(
          hintText: '원하는 태그를 입력해주세요',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.edit_rounded,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          // 직접 입력 시 칩 선택 해제
          if (value.isNotEmpty && !_predefinedTags.contains(value)) {
            setState(() {
              _selectedTagIndex = -1;
            });
          }
          // 입력값이 사전 정의된 태그와 일치하면 해당 칩 선택
          final matchIndex = _predefinedTags.indexOf(value);
          if (matchIndex != -1) {
            setState(() {
              _selectedTagIndex = matchIndex;
            });
          }
        },
      ),
    );
  }

  /// 시간 ChoiceChip 목록
  Widget _buildTimeChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timeOptions.map((minutes) {
        final isSelected = _selectedTime == minutes;

        return ChoiceChip(
          label: Text('$minutes분'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTime = minutes;
            });
          },
          // 스타일링
          selectedColor: focusPrimaryColor,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: isSelected
                  ? focusPrimaryColor
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        );
      }).toList(),
    );
  }

  /// 입장하기/저장하기 버튼
  Widget _buildEnterButton(BuildContext context) {
    // 수정 모드에 따른 버튼 텍스트와 아이콘
    final buttonText = widget.isEditMode ? '저장하기' : '입장하기';
    final buttonIcon = widget.isEditMode
        ? Icons.check_rounded
        : Icons.arrow_forward_rounded;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _onEnterPressed(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: focusPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 8,
          shadowColor: focusPrimaryColor.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: GoogleFonts.silkscreen(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            Icon(buttonIcon, size: 24),
          ],
        ),
      ),
    );
  }

  /// 입장하기 버튼 클릭 핸들러
  void _onEnterPressed(BuildContext context) {
    // Provider에 설정값 저장
    final timerProvider = context.read<TimerProvider>();

    // 태그 설정 (빈 값이면 기본값 사용)
    final tag = _tagController.text.trim().isEmpty
        ? '집중'
        : _tagController.text.trim();
    timerProvider.setTag(tag);

    // 시간 설정
    timerProvider.setTime(_selectedTime);

    if (widget.isEditMode) {
      // 수정 모드: 뒤로 가기 (pop)
      Navigator.of(context).pop();
    } else {
      // 처음 진입: HomeScreen으로 이동 (pushReplacement)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 페이드 인 애니메이션
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
}


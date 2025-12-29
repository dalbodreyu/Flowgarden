// constants.dart
// 앱 전역에서 사용되는 상수 관리
// 컬러, 시간 설정 값, 테마 등

import 'package:flutter/material.dart';

// ============================================================
// 타이머 설정
// ============================================================
const int focusDurationMinutes = 25;  // 집중 시간 (분)
const int restDurationMinutes = 5;    // 휴식 시간 (분)

// ============================================================
// 컬러 팔레트
// ============================================================
// Focus Mode (집중): 차분한 밤/비 오는 분위기
const Color focusPrimaryColor = Color(0xFF1A237E);    // Deep Indigo
const Color focusSecondaryColor = Color(0xFF283593);  // Indigo
const Color focusBackgroundColor = Color(0xFF0D1B2A); // Dark Blue

// Rest Mode (휴식): 따뜻한 낮/햇살 분위기
const Color restPrimaryColor = Color(0xFFFF8F00);     // Warm Orange
const Color restSecondaryColor = Color(0xFFFFCA28);   // Soft Yellow
const Color restBackgroundColor = Color(0xFFFFF8E1);  // Cream

// ============================================================
// 공통 UI 스타일
// ============================================================
const double borderRadius = 8.0;
const double buttonPadding = 16.0;


import 'package:flutter/material.dart';

import '../models/measurement.dart';

/// 마커·오차 원 색상 (PRD 2.2 S2, Q-10): WiFi 파랑 / LTE·5G 주황 / 없음·알 수 없음 회색
class AppColors {
  AppColors._();

  static const Color wifi = Color(0xFF1E88E5);
  static const Color mobile = Color(0xFFFB8C00);
  static const Color neutral = Color(0xFF9E9E9E);

  static Color forConnection(ConnectionType type) => switch (type) {
        ConnectionType.wifi => wifi,
        ConnectionType.lte ||
        ConnectionType.fiveG ||
        ConnectionType.mobileOther =>
          mobile,
        ConnectionType.none || ConnectionType.unknown => neutral,
      };
}

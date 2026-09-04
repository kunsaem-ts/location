import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/app/colors.dart';
import 'package:location_check/models/measurement.dart';

void main() {
  test('연결망별 마커 색: WiFi 파랑 / LTE·5G·이동통신 주황 / 없음·알 수 없음 회색 (Q-10)', () {
    expect(AppColors.forConnection(ConnectionType.wifi), AppColors.wifi);
    expect(AppColors.forConnection(ConnectionType.lte), AppColors.mobile);
    expect(AppColors.forConnection(ConnectionType.fiveG), AppColors.mobile);
    expect(AppColors.forConnection(ConnectionType.mobileOther), AppColors.mobile);
    expect(AppColors.forConnection(ConnectionType.none), AppColors.neutral);
    expect(AppColors.forConnection(ConnectionType.unknown), AppColors.neutral);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app/constants.dart';
import '../app/strings.dart';
import '../models/measurement.dart';

/// 정보 패널 (FR-05, FR-07, FR-08, FR-14).
class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.current,
    required this.reducedAccuracy,
    required this.error,
  });

  final Measurement? current;
  final bool reducedAccuracy;
  final String? error;

  static final _timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String coordinateText(double v) =>
      v.toStringAsFixed(AppConstants.coordinateDecimals);

  /// "GPS 추정 (제공자 fused, ±8 m)" / iOS: "WiFi 추정 (±45 m)"
  static String sourceText(Measurement m) {
    final provider = m.locationProvider;
    final detail = provider == null
        ? '±${m.accuracyM.round()} m'
        : '${AppStrings.providerPrefix}$provider, ±${m.accuracyM.round()} m';
    return '${m.sourceEstimate.label} ($detail)';
  }

  /// 위도·경도를 "37.566535, 126.977969" 형식으로 복사하고 스낵바로 알린다.
  Future<void> _copyCoordinates(BuildContext context, Measurement m) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = '${coordinateText(m.latitude)}, ${coordinateText(m.longitude)}';
    String message = AppStrings.coordinatesCopied;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      message = '${AppStrings.copyFailed} ($e)';
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final m = current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      children: [
        if (error != null)
          _Badge(text: error!, color: Theme.of(context).colorScheme.error),
        if (reducedAccuracy)
          const _Badge(text: AppStrings.badgeReducedAccuracy, color: Colors.orange),
        if (m == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(AppStrings.noResultYet),
          )
        else ...[
          if (m.timedOut)
            const _Badge(text: AppStrings.badgeTimedOut, color: Colors.orange),
          if (m.isMock == true)
            _Badge(
              text: AppStrings.badgeMockLocation,
              color: Theme.of(context).colorScheme.error,
            ),
          InkWell(
            onTap: () => _copyCoordinates(context, m),
            child: Column(
              children: [
                _Row(AppStrings.labelLatitude, coordinateText(m.latitude)),
                _Row(AppStrings.labelLongitude, coordinateText(m.longitude)),
              ],
            ),
          ),
          _Row(AppStrings.labelAccuracy, '± ${m.accuracyM.round()} m'),
          _Row(AppStrings.labelConnection, m.connectionType.label),
          _Row(AppStrings.labelSource, sourceText(m)),
          _Row(AppStrings.labelMeasuredAt, _timeFormat.format(m.measuredAt)),
          if (m.distanceFromPrevM != null)
            _Row(
              AppStrings.labelDistance,
              '${m.distanceFromPrevM!.toStringAsFixed(1)} m',
            ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

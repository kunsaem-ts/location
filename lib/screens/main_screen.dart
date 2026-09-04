import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/strings.dart';
import '../widgets/info_panel.dart';
import '../widgets/measurement_map.dart';
import 'history_screen.dart';

/// S2. 메인 화면: 지도(상단 55%) + 정보 패널 + 측정 버튼 (PRD 2.2).
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Future<void> _measure(BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    await state.measure();
    final saveError = state.saveError;
    if (saveError != null) {
      // 저장 실패는 스낵바로 알리고 화면 결과는 유지한다 (EX-14).
      messenger.showSnackBar(SnackBar(content: Text(saveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final current = state.current;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: AppStrings.historyTitle,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // E3. 오프라인 배너: 전체 화면이 아니라 상단 배너, 측정은 계속 허용 (FR-12)
          if (state.offline)
            MaterialBanner(
              content: const Text(AppStrings.offlineBanner),
              leading: const Icon(Icons.wifi_off),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            flex: 55,
            child: MeasurementMap(current: current),
          ),
          Expanded(
            flex: 45,
            child: InfoPanel(
              current: current,
              reducedAccuracy: state.reducedAccuracy,
              error: state.lastError,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            // 측정 중에는 비활성화해 중복 요청을 막는다 (FR-15).
            onPressed: state.measuring ? null : () => _measure(context, state),
            icon: state.measuring
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_buttonLabel(state)),
          ),
        ),
      ),
    );
  }

  static String _buttonLabel(AppState state) {
    if (state.measuring) {
      return '${AppStrings.measuring} '
          '(${state.elapsedSeconds}${AppStrings.measuringSecondsSuffix})';
    }
    return state.current == null ? AppStrings.measure : AppStrings.remeasure;
  }
}

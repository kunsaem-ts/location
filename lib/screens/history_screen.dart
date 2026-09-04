import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/colors.dart';
import '../app/strings.dart';
import '../models/measurement.dart';
import '../widgets/info_panel.dart';

/// S3. 최근 결과 목록 (FR-10). 항목 탭 → 지도 표시, 스와이프 → 단건 삭제, 메뉴 → 전체 삭제.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static final _timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<void> _confirmDeleteAll(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAllConfirmTitle),
        content: const Text(AppStrings.deleteAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.deleteAll),
          ),
        ],
      ),
    );
    if (ok == true) await state.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.history;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.deleteAll,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed:
                items.isEmpty ? null : () => _confirmDeleteAll(context, state),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text(AppStrings.historyEmpty))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _HistoryTile(
                measurement: items[i],
                timeText: _timeFormat.format(items[i].measuredAt),
                selected: items[i].id == state.current?.id,
                onTap: () {
                  state.select(items[i]);
                  Navigator.pop(context);
                },
                onDismissed: () => state.delete(items[i]),
              ),
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.measurement,
    required this.timeText,
    required this.selected,
    required this.onTap,
    required this.onDismissed,
  });

  final Measurement measurement;
  final String timeText;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    final color = AppColors.forConnection(m.connectionType);
    final distance = m.distanceFromPrevM;
    final subtitle = [
      '${InfoPanel.coordinateText(m.latitude)}, ${InfoPanel.coordinateText(m.longitude)}',
      '±${m.accuracyM.round()} m',
      if (distance != null)
        '${AppStrings.labelDistance} ${distance.toStringAsFixed(1)} m',
    ].join(' · ');

    return Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: ListTile(
        selected: selected,
        leading: Chip(
          label: Text(m.connectionType.label),
          backgroundColor: color.withValues(alpha: 0.15),
          side: BorderSide(color: color),
          labelStyle: TextStyle(color: color),
          visualDensity: VisualDensity.compact,
        ),
        title: Text(timeText),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}

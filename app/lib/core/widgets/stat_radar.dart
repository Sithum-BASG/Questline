import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_chip.dart';

/// Four-stat radar. Values are raw XP totals for the chosen window.
class StatRadarValues {
  const StatRadarValues({
    required this.intellect,
    required this.vitality,
    required this.craft,
    required this.charisma,
  });

  final double intellect;
  final double vitality;
  final double craft;
  final double charisma;

  double get max => [intellect, vitality, craft, charisma].fold(0.0, (a, b) => a > b ? a : b);

  /// Sums XP from [days] calendar days ending on [end] (inclusive).
  static StatRadarValues fromDailyStats(
    Iterable<({DateTime day, int intellect, int vitality, int craft, int charisma})> rows, {
    required int days,
    required DateTime end,
  }) {
    final start = DateTime.utc(end.year, end.month, end.day).subtract(Duration(days: days - 1));
    var intellect = 0;
    var vitality = 0;
    var craft = 0;
    var charisma = 0;
    for (final row in rows) {
      final day = DateTime.utc(row.day.year, row.day.month, row.day.day);
      if (day.isBefore(start) || day.isAfter(DateTime.utc(end.year, end.month, end.day))) continue;
      intellect += row.intellect;
      vitality += row.vitality;
      craft += row.craft;
      charisma += row.charisma;
    }
    return StatRadarValues(
      intellect: intellect.toDouble(),
      vitality: vitality.toDouble(),
      craft: craft.toDouble(),
      charisma: charisma.toDouble(),
    );
  }
}

class StatRadar extends StatefulWidget {
  const StatRadar({
    super.key,
    required this.valuesFor30,
    required this.valuesFor7,
    this.initialDays = 30,
  });

  final StatRadarValues valuesFor30;
  final StatRadarValues valuesFor7;
  final int initialDays;

  @override
  State<StatRadar> createState() => _StatRadarState();
}

class _StatRadarState extends State<StatRadar> {
  late int _days = widget.initialDays;

  StatRadarValues get _values => _days == 7 ? widget.valuesFor7 : widget.valuesFor30;

  @override
  Widget build(BuildContext context) {
    final values = _values;
    final peak = values.max <= 0 ? 1.0 : values.max;
    return Column(
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          children: [
            QChip(label: '30 days', selected: _days == 30, onTap: () => setState(() => _days = 30)),
            QChip(label: '7 days', selected: _days == 7, onTap: () => setState(() => _days = 7)),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 220,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  dataEntries: [
                    RadarEntry(value: values.intellect / peak),
                    RadarEntry(value: values.vitality / peak),
                    RadarEntry(value: values.craft / peak),
                    RadarEntry(value: values.charisma / peak),
                  ],
                  fillColor: AppColors.awakeningTeal.withValues(alpha: 0.25),
                  borderColor: AppColors.tealDeep,
                  entryRadius: 3,
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: AppColors.line),
              tickCount: 3,
              ticksTextStyle: AppText.caption.copyWith(color: Colors.transparent),
              tickBorderData: const BorderSide(color: AppColors.line),
              gridBorderData: const BorderSide(color: AppColors.line),
              getTitle: (index, _) {
                const labels = ['Intellect', 'Vitality', 'Craft', 'Charisma'];
                return RadarChartTitle(text: labels[index], angle: 0);
              },
              titleTextStyle: AppText.caption.copyWith(color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

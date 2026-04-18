/// 集計モード：最新1回のみ or 最新3回分（slots 全部）
import '../../localization/app_localizations.dart';

enum AggregationMode { latest1, latest3 }

extension AggregationModeExt on AggregationMode {
  String label(AppLocalizations l10n) {
    switch (this) {
      case AggregationMode.latest1:
        return l10n.aggregationLatest1Description;
      case AggregationMode.latest3:
        return l10n.aggregationLatest3Description;
    }
  }

  int toInt() => index;
}

class AggregationModeFactory {
  static AggregationMode fromInt(int v) {
    if (v < 0 || v >= AggregationMode.values.length) return AggregationMode.latest1;
    return AggregationMode.values[v];
  }
}


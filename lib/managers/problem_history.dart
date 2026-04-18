import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import '../models/math_problem.dart';

class ProblemHistory {
  List<DateTime> solvedDates;
  List<DateTime> failedDates;

  ProblemHistory({List<DateTime>? solved, List<DateTime>? failed})
      : solvedDates = solved ?? [],
        failedDates = failed ?? [];

  Map<String, dynamic> toJson() => {
        'solved': solvedDates.map((d) => d.toIso8601String()).toList(),
        'failed': failedDates.map((d) => d.toIso8601String()).toList(),
      };

  factory ProblemHistory.fromJson(Map<String, dynamic> json) => ProblemHistory(
        solved: (json['solved'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList(),
        failed: (json['failed'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList(),
      );
}

class ProblemHistoryManager {
  final Map<String, ProblemHistory> _historyMap = {};
  final Lock _saveLock = Lock();

  /// If true, only store one entry per local date (yyyy-MM-dd).
  /// If false, store full DateTime (multiple entries per same day allowed).
  final bool dateOnlyMode;

  ProblemHistoryManager({this.dateOnlyMode = true});

  String _makeKeyFromParts(String category, int no) =>
      Uri.encodeComponent(category) + '::' + no.toString();

  String _makeKey(MathProblem problem) =>
      _makeKeyFromParts(problem.category, problem.no);

  ProblemHistory? getHistory(MathProblem problem) =>
      _historyMap[_makeKey(problem)];

  List<DateTime> getSolvedDates(MathProblem problem) =>
      _historyMap[_makeKey(problem)]?.solvedDates ?? [];

  List<DateTime> getFailedDates(MathProblem problem) =>
      _historyMap[_makeKey(problem)]?.failedDates ?? [];

  DateTime _todayLocalDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> markSolved(MathProblem problem) async {
    final key = _makeKey(problem);
    final now = dateOnlyMode ? _todayLocalDateOnly() : DateTime.now();
    _historyMap.putIfAbsent(key, () => ProblemHistory());

    final list = _historyMap[key]!.solvedDates;
    if (dateOnlyMode) {
      final exists = list.any((d) =>
          d.year == now.year && d.month == now.month && d.day == now.day);
      if (!exists) {
        list.add(now);
        await _save();
      }
    } else {
      list.add(now);
      await _save();
    }
  }

  Future<void> markFailed(MathProblem problem) async {
    final key = _makeKey(problem);
    final now = dateOnlyMode ? _todayLocalDateOnly() : DateTime.now();
    _historyMap.putIfAbsent(key, () => ProblemHistory());

    final list = _historyMap[key]!.failedDates;
    if (dateOnlyMode) {
      final exists = list.any((d) =>
          d.year == now.year && d.month == now.month && d.day == now.day);
      if (!exists) {
        list.add(now);
        await _save();
      }
    } else {
      list.add(now);
      await _save();
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('history_map');
    if (jsonString == null) return;
    try {
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      _historyMap.clear();
      jsonData.forEach((k, v) {
        _historyMap[k] = ProblemHistory.fromJson(Map<String, dynamic>.from(v));
      });
    } catch (e) {
      // If load fails, log and reset to empty to avoid crashing the app.
      print('ProblemHistoryManager.load failed: $e');
      _historyMap.clear();
      await prefs.remove('history_map');
    }
  }

  Future<void> _save() async {
    await _saveLock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _historyMap.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString('history_map', jsonEncode(jsonData));
    });
  }

  /// Utility: export the history map as JSON string (for backup)
  String exportJson() => jsonEncode(_historyMap.map((k, v) => MapEntry(k, v.toJson())));

  /// Utility: import history map from JSON string (for restore)
  Future<void> importJson(String jsonString) async {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      _historyMap.clear();
      jsonData.forEach((k, v) {
        _historyMap[k] = ProblemHistory.fromJson(Map<String, dynamic>.from(v));
      });
      await _save();
    } catch (e) {
      print('ProblemHistoryManager.importJson failed: $e');
      rethrow;
    }
  }
}

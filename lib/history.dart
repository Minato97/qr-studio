import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  HistoryEntry({required this.text, required this.scanned, required this.time});

  final String text;
  final bool scanned;
  final DateTime time;

  Map<String, dynamic> toJson() =>
      {'t': text, 's': scanned, 'd': time.millisecondsSinceEpoch};

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        text: j['t'] as String,
        scanned: j['s'] as bool,
        time: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
      );
}

class HistoryStore extends ChangeNotifier {
  HistoryStore._();
  static final instance = HistoryStore._();

  static const _key = 'history_v1';
  static const _max = 200;

  List<HistoryEntry> entries = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    entries = raw
        .map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> add(String text, {required bool scanned}) async {
    entries.removeWhere((e) => e.text == text && e.scanned == scanned);
    entries.insert(
        0, HistoryEntry(text: text, scanned: scanned, time: DateTime.now()));
    if (entries.length > _max) entries = entries.sublist(0, _max);
    await _save();
  }

  Future<void> remove(HistoryEntry entry) async {
    entries.remove(entry);
    await _save();
  }

  Future<void> clear() async {
    entries = [];
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, entries.map((e) => jsonEncode(e.toJson())).toList());
  }
}

import 'package:flutter/foundation.dart';

/// Shared selection of character IDs for map + feed filtering.
class CharacterFilterController extends ChangeNotifier {
  List<int> selectedIds = const [];

  bool get hasFilter => selectedIds.isNotEmpty;

  void setSelectedIds(List<int> ids) {
    final next = List<int>.unmodifiable(ids);
    if (_same(selectedIds, next)) {
      return;
    }
    selectedIds = next;
    notifyListeners();
  }

  void add(int id) {
    if (selectedIds.contains(id)) {
      return;
    }
    selectedIds = List.unmodifiable([...selectedIds, id]);
    notifyListeners();
  }

  void remove(int id) {
    if (!selectedIds.contains(id)) {
      return;
    }
    selectedIds = List.unmodifiable([
      for (final value in selectedIds)
        if (value != id) value,
    ]);
    notifyListeners();
  }

  void clear() {
    if (selectedIds.isEmpty) {
      return;
    }
    selectedIds = const [];
    notifyListeners();
  }

  /// Toggle a single-character filter (post detail tag behavior).
  void toggleSolo(int id) {
    final solo = selectedIds.length == 1 && selectedIds.first == id;
    selectedIds = solo ? const [] : List.unmodifiable([id]);
    notifyListeners();
  }

  bool _same(List<int> a, List<int> b) {
    if (identical(a, b) || a.length != b.length) {
      return a.length == b.length && identical(a, b);
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

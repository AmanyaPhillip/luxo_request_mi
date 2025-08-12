import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class HistoryProvider with ChangeNotifier {
  List<Ticket> _tickets = [];

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('requestHistory');

      if (historyString != null) {
        final historyList = jsonDecode(historyString) as List;
        _tickets = historyList.map((ticketMap) => Ticket.fromJson(ticketMap)).toList();
        _tickets.sort((a, b) => b.requestDate.compareTo(a.requestDate));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = _tickets.map((ticket) => ticket.toJson()).toList();
      final historyString = jsonEncode(historyList);

      await prefs.setString('requestHistory', historyString);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> addTicket(String status, UserData submittedData) async {
    final newTicket = Ticket(
      status: status,
      requestDate: DateTime.now(),
      submittedData: submittedData,
    );

    _tickets.insert(0, newTicket);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('requestHistory');
    _tickets.clear();
    notifyListeners();
  }

  int getSuccessCount() {
    return _tickets.where((ticket) => ticket.status == 'Success').length;
  }

  int getFailCount() {
    return _tickets.where((ticket) => ticket.status == 'Fail').length;
  }

  List<Ticket> getRecentTickets({int limit = 5}) {
    return _tickets.take(limit).toList();
  }
}
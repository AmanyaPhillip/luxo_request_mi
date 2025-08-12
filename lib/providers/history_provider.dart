import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class HistoryProvider with ChangeNotifier {
  List<Ticket> _tickets = [];

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  // Load history from SharedPreferences
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('requestHistory');
      
      if (historyString != null) {
        final historyList = jsonDecode(historyString) as List;
        _tickets = historyList.map((ticketMap) => Ticket.fromJson(ticketMap)).toList();
        // Sort by date (newest first)
        _tickets.sort((a, b) => b.requestDate.compareTo(a.requestDate));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  // Save history to SharedPreferences
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

  // Add a new ticket to history
  Future<void> addTicket(String projectName, String status) async {
    final newTicket = Ticket(
      projectName: projectName,
      status: status,
      requestDate: DateTime.now(),
    );
    
    _tickets.insert(0, newTicket); // Add to beginning for newest first
    await _saveHistory();
    notifyListeners();
  }

  // Clear all history (for testing purposes)
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('requestHistory');
    _tickets.clear();
    notifyListeners();
  }

  // Get tickets count by status
  int getSuccessCount() {
    return _tickets.where((ticket) => ticket.status == 'Success').length;
  }

  int getFailCount() {
    return _tickets.where((ticket) => ticket.status == 'Fail').length;
  }

  // Get recent tickets (last 5)
  List<Ticket> getRecentTickets({int limit = 5}) {
    return _tickets.take(limit).toList();
  }
}
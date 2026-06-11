import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/complaint.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Complaint> get pendingComplaints =>
      _complaints.where((c) => c.status == ComplaintStatus.pending).toList();

  List<Complaint> get escalatedComplaints =>
      _complaints.where((c) => c.status == ComplaintStatus.escalated).toList();

  List<Complaint> get resolvedComplaints =>
      _complaints.where((c) => c.status == ComplaintStatus.resolved).toList();

  List<Complaint> complaintsForUser(String userId) =>
      _complaints.where((c) => c.citizenId == userId).toList();

  List<Complaint> complaintsForLevel(GovernmentLevel level) =>
      _complaints.where((c) => c.currentLevel == level).toList();

  Map<String, int> get stats => {
        'total': _complaints.length,
        'pending': pendingComplaints.length,
        'inProgress': _complaints
            .where((c) => c.status == ComplaintStatus.inProgress)
            .length,
        'escalated': escalatedComplaints.length,
        'resolved': resolvedComplaints.length,
        'closed':
            _complaints.where((c) => c.status == ComplaintStatus.closed).length,
      };

  Map<String, int> get categoryStats {
    final Map<String, int> result = {};
    for (final c in _complaints) {
      result[c.category.name] = (result[c.category.name] ?? 0) + 1;
    }
    return result;
  }

  /// Loads complaints for a specific user from their private storage key.
  /// New users start with an empty list. Call this after login/register.
  Future<void> loadForUser(String userId) async {
    _userId = userId;
    _complaints = [];
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'complaints_$userId';
      final data = prefs.getString(key);
      debugPrint('📂 loadForUser: userId=$userId, key=$key, found=${data != null}, length=${data?.length ?? 0}');
      if (data != null) {
        final List list = jsonDecode(data);
        _complaints = list.map((e) => Complaint.fromJson(e)).toList();
        debugPrint('📂 loadForUser: loaded ${_complaints.length} complaints');
        await checkAndEscalate();
      }
    } catch (e, stack) {
      debugPrint('❌ loadForUser error: $e\n$stack');
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clears in-memory complaints. Call this on logout so the next
  /// user starts fresh until loadForUser is called.
  void clearComplaints() {
    _complaints = [];
    _userId = null;
    notifyListeners();
  }

  Future<Complaint> submitComplaint({
    required String citizenId,
    required String citizenName,
    required String citizenPhone,
    required String title,
    required String description,
    required ComplaintCategory category,
    required String mtaa,
    required String ward,
    required String district,
    required String region,
    bool isAnonymous = false,
    bool isUrgent = false,
    List<String>? attachments,
  }) async {
    // Always keep _userId in sync with the submitting citizen so
    // _saveComplaints() writes to the right key even if loadForUser
    // hasn't been called yet (e.g. first-frame race).
    _userId = citizenId;
    debugPrint('📝 submitComplaint: citizenId=$citizenId, _userId=$_userId');

    final complaint = Complaint(
      id: _generateId(),
      citizenId: citizenId,
      citizenName: isAnonymous ? 'Anonymous' : citizenName,
      citizenPhone: citizenPhone,
      title: title,
      description: description,
      category: category,
      status: ComplaintStatus.pending,
      currentLevel: GovernmentLevel.mtaa,
      mtaa: mtaa,
      ward: ward,
      district: district,
      region: region,
      submittedAt: DateTime.now(),
      isAnonymous: isAnonymous,
      isUrgent: isUrgent,
      attachments: attachments ?? [],
      trackingCode: _generateTrackingCode(),
      priorityScore: isUrgent ? 10 : 0,
    );

    _complaints.insert(0, complaint);
    await _saveComplaints();
    notifyListeners();
    return complaint;
  }

  Future<void> updateStatus(String id, ComplaintStatus status) async {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return;

    _complaints[index].status = status;
    _complaints[index].updatedAt = DateTime.now();
    if (status == ComplaintStatus.resolved) {
      _complaints[index].resolvedAt = DateTime.now();
    }

    await _saveComplaints();
    notifyListeners();
  }

  Future<void> addComment(String complaintId, Comment comment) async {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index == -1) return;

    _complaints[index].comments.add(comment);
    _complaints[index].updatedAt = DateTime.now();

    await _saveComplaints();
    notifyListeners();
  }

  Future<void> upvoteComplaint(String id) async {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return;

    _complaints[index].upvotes++;
    _complaints[index].priorityScore++;

    await _saveComplaints();
    notifyListeners();
  }

  Future<void> manualEscalate(String id, String reason) async {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return;

    _complaints[index].escalate(reason);

    await _saveComplaints();
    notifyListeners();
  }

  /// Auto-escalation: checks all active complaints and escalates overdue ones
  Future<int> checkAndEscalate() async {
    int escalated = 0;
    bool changed = false;

    for (int i = 0; i < _complaints.length; i++) {
      final complaint = _complaints[i];
      if (complaint.shouldEscalate()) {
        final daysAllowed =
            Complaint.escalationDays[complaint.currentLevel] ?? 7;
        complaint.escalate(
          'Auto-escalated: No action taken within $daysAllowed days at ${complaint.levelLabel} level.',
        );
        escalated++;
        changed = true;
      }
    }

    if (changed) {
      await _saveComplaints();
      notifyListeners();
    }

    return escalated;
  }

  Complaint? findByTrackingCode(String code) {
    try {
      return _complaints.firstWhere(
          (c) => c.trackingCode.toUpperCase() == code.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveComplaints() async {
    if (_userId == null) {
      debugPrint('❌ _saveComplaints: _userId is null, save skipped');
      return;
    }
    final key = 'complaints_$_userId';
    debugPrint('💾 _saveComplaints: key=$key, count=${_complaints.length}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(_complaints.map((c) => c.toJson()).toList()),
    );
  }

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  String _generateTrackingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'SR${List.generate(6, (_) => chars[random.nextInt(chars.length)]).join()}';
  }
}

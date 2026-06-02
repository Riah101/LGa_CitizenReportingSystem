import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/complaint.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  String? _error;

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

  Future<void> loadComplaints() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('complaints');
      if (data != null) {
        final List list = jsonDecode(data);
        _complaints = list.map((e) => Complaint.fromJson(e)).toList();
      } else {
        // Load demo data
        _complaints = _generateDemoComplaints();
        await _saveComplaints();
      }
      
      // Run auto-escalation check
      await checkAndEscalate();
    } catch (e) {
      _error = e.toString();
      _complaints = _generateDemoComplaints();
    }

    _isLoading = false;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'complaints',
      jsonEncode(_complaints.map((c) => c.toJson()).toList()),
    );
  }

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  String _generateTrackingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'SR' +
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  List<Complaint> _generateDemoComplaints() {
    final now = DateTime.now();
    return [
      Complaint(
        id: '1',
        citizenId: 'demo_user',
        citizenName: 'Amina Hassan',
        citizenPhone: '+255712345678',
        title: 'Barabara Imeharibiwa - Broken Road',
        description:
            'Barabara ya Uhuru Street ina mashimo makubwa sana ambayo yanasababisha ajali nyingi. The road has large potholes causing accidents daily.',
        category: ComplaintCategory.infrastructure,
        status: ComplaintStatus.pending,
        currentLevel: GovernmentLevel.mtaa,
        mtaa: 'Kariakoo',
        ward: 'Kariakoo',
        district: 'Ilala',
        region: 'Dar es Salaam',
        submittedAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        trackingCode: 'SR4K9X2M',
        upvotes: 24,
        isUrgent: false,
        priorityScore: 24,
      ),
      Complaint(
        id: '2',
        citizenId: 'demo_user2',
        citizenName: 'John Makundi',
        citizenPhone: '+255787654321',
        title: 'Maji Safi Hayapo - No Clean Water',
        description:
            'Kata yetu haina maji safi kwa wiki mbili. Our ward has had no clean water supply for two weeks now.',
        category: ComplaintCategory.water,
        status: ComplaintStatus.escalated,
        currentLevel: GovernmentLevel.ward,
        mtaa: 'Mwananyamala',
        ward: 'Mwananyamala',
        district: 'Kinondoni',
        region: 'Dar es Salaam',
        submittedAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 8)),
        escalationHistory: [
          EscalationHistory(
            fromLevel: GovernmentLevel.mtaa,
            toLevel: GovernmentLevel.ward,
            escalatedAt: now.subtract(const Duration(days: 8)),
            reason: 'Auto-escalated: No action taken within 7 days at Mtaa level.',
          ),
        ],
        trackingCode: 'SR7B3N1P',
        upvotes: 87,
        isUrgent: true,
        priorityScore: 97,
      ),
      Complaint(
        id: '3',
        citizenId: 'demo_user3',
        citizenName: 'Fatuma Suleiman',
        citizenPhone: '+255765432198',
        title: 'Hospitali Haina Dawa - Hospital Lacks Medicine',
        description:
            'Hospitali ya Wilaya haina dawa za msingi. The district hospital has run out of essential medicines.',
        category: ComplaintCategory.health,
        status: ComplaintStatus.inProgress,
        currentLevel: GovernmentLevel.district,
        mtaa: 'Temeke',
        ward: 'Temeke',
        district: 'Temeke',
        region: 'Dar es Salaam',
        submittedAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 5)),
        escalationHistory: [
          EscalationHistory(
            fromLevel: GovernmentLevel.mtaa,
            toLevel: GovernmentLevel.ward,
            escalatedAt: now.subtract(const Duration(days: 38)),
            reason: 'Auto-escalated after 7 days',
          ),
          EscalationHistory(
            fromLevel: GovernmentLevel.ward,
            toLevel: GovernmentLevel.district,
            escalatedAt: now.subtract(const Duration(days: 24)),
            reason: 'Auto-escalated after 14 days',
          ),
        ],
        comments: [
          Comment(
            id: 'c1',
            authorId: 'officer1',
            authorName: 'DCC Temeke',
            authorRole: 'District Commissioner',
            content: 'We have contacted the Ministry of Health. Supply delivery expected within 3 days.',
            createdAt: now.subtract(const Duration(days: 5)),
            isOfficial: true,
          ),
        ],
        trackingCode: 'SR2D8F5R',
        upvotes: 156,
        isUrgent: true,
        priorityScore: 166,
      ),
      Complaint(
        id: '4',
        citizenId: 'demo_user4',
        citizenName: 'Peter Mwanga',
        citizenPhone: '+255754321098',
        title: 'Taa za Mitaani Hazifanyi Kazi',
        description:
            'Street lights in our area have been off for a month, creating security concerns at night.',
        category: ComplaintCategory.electricity,
        status: ComplaintStatus.resolved,
        currentLevel: GovernmentLevel.mtaa,
        mtaa: 'Mikocheni',
        ward: 'Mikocheni',
        district: 'Kinondoni',
        region: 'Dar es Salaam',
        submittedAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
        resolvedAt: now.subtract(const Duration(days: 2)),
        trackingCode: 'SR9W1L6T',
        upvotes: 43,
        priorityScore: 43,
      ),
    ];
  }
}

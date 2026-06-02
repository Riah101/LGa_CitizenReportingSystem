import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/complaint_card.dart';
import 'complaint_detail_screen.dart';

class ComplaintsListScreen extends StatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Complaint> _filterComplaints(
      List<Complaint> all, ComplaintStatus? status) {
    var list = status == null ? all : all.where((c) => c.status == status).toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) {
        final q = _searchQuery.toLowerCase();
        return c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.mtaa.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ComplaintProvider>();
    final userId = auth.currentUser?.id ?? '';
    final myComplaints = provider.complaintsForUser(userId);
    final allComplaints = provider.complaints;

    final tabs = [
      (l.all, null),
      (l.statusPending, ComplaintStatus.pending),
      (l.statusInProgress, ComplaintStatus.inProgress),
      (l.statusEscalated, ComplaintStatus.escalated),
      (l.statusResolved, ComplaintStatus.resolved),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myComplaints),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: tabs
                .map((t) => Tab(
                      child: Row(
                        children: [
                          Text(t.$1, style: const TextStyle(fontSize: 13)),
                          if (t.$2 != null) ...[
                            const SizedBox(width: 4),
                            _CountBadge(
                              count: _filterComplaints(allComplaints, t.$2).length,
                            ),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs
                  .map((t) => _ComplaintTab(
                        complaints: _filterComplaints(allComplaints, t.$2),
                        l: l,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen),
      ),
    );
  }
}

class _ComplaintTab extends StatelessWidget {
  final List<Complaint> complaints;
  final AppLocalizations l;

  const _ComplaintTab({required this.complaints, required this.l});

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(l.noComplaintsYet,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => ComplaintCard(
        complaint: complaints[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ComplaintDetailScreen(complaint: complaints[i]),
          ),
        ),
      ),
    );
  }
}

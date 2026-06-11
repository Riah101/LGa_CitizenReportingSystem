import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../complaints/complaints_list_screen.dart';
import '../complaints/submit_complaint_screen.dart';
import '../complaints/track_screen.dart';
import 'dashboard_screen.dart';
import 'officer_dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ComplaintProvider>().loadForUser(user.id);
      }
    });
  }

  void switchToComplaints() => setState(() => _currentIndex = 1);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final isOfficer = user?.isOfficer ?? false;

    final pages = isOfficer
        ? [
            const OfficerDashboardScreen(),
            const TrackScreen(),
            const ProfileScreen(),
          ]
        : [
            DashboardScreen(onViewAll: switchToComplaints),
            const ComplaintsListScreen(),
            const TrackScreen(),
            const ProfileScreen(),
          ];

    final navItems = isOfficer
        ? [
            (Icons.dashboard_outlined, Icons.dashboard_rounded, l.home),
            (Icons.search_outlined, Icons.search_rounded, l.track),
            (Icons.person_outline_rounded, Icons.person_rounded, l.profile),
          ]
        : [
            (Icons.home_outlined, Icons.home_rounded, l.home),
            (Icons.list_alt_outlined, Icons.list_alt_rounded, l.myComplaints),
            (Icons.search_outlined, Icons.search_rounded, l.track),
            (Icons.person_outline_rounded, Icons.person_rounded, l.profile),
          ];

    // Clamp index when switching roles
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      floatingActionButton: isOfficer
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubmitComplaintScreen()),
              ),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                l.newComplaint,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              elevation: 4,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: isOfficer ? null : const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < navItems.length; i++) ...[
                if (!isOfficer && i == 2) const SizedBox(width: 60),
                _NavItem(
                  icon: navItems[i].$1,
                  activeIcon: navItems[i].$2,
                  label: navItems[i].$3,
                  index: i,
                  currentIndex: safeIndex,
                  onTap: (idx) => setState(() => _currentIndex = idx),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

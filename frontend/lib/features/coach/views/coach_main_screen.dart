import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../../advanced/views/advanced_detail_screens.dart';
import '../../auth/views/welcome_screen.dart';
import '../../main/views/main_screen.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/notification_models.dart';
import '../../../core/services/realtime_notification_service.dart';
import '../../../core/services/notification_handler.dart';
import '../../coach_pt/views/coach_meal_plan_select_client_screen.dart';
import '../../coach_pt/views/coach_report_detail_screen.dart';
import '../../coach_pt/views/coach_reports_tab_screen.dart';
import '../../coach_pt/providers/coach_report_provider.dart';
import '../../coach_chat/views/coach_chat_screen.dart';
import '../providers/coach_badge_provider.dart';
import '../repositories/coach_application_repository.dart';
import '../widgets/coach_profile_overview.dart';
import 'coach_application_screen.dart';

const Color _coachPrimary = Color(0xFF1a7a4a);

class CoachMainScreen extends StatefulWidget {
  const CoachMainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen> {
  late int _currentIndex;

  late final List<Widget> _pages;
  final _profileRepo = ProfileRepository();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
    _pages = [
      const _CoachClientsTab(),
      const CoachMealPlanSelectClientScreen(),
      const CoachReportsTabScreen(),
      _CoachNotificationsTab(onOpenTab: _selectTab),
      const _CoachProfileTab(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _enforceRoleGuard());
  }

  void _selectTab(int index) {
    if (!mounted || index < 0 || index >= _pages.length) return;
    setState(() => _currentIndex = index);
  }

  /// Guard: nếu user hiện tại không phải role `coach` thì đẩy về MainScreen.
  /// Tránh trường hợp deep-link / state persisted đưa Gymer vào CoachMainScreen.
  Future<void> _enforceRoleGuard() async {
    try {
      final profile = await _profileRepo.getMyProfile().timeout(
        const Duration(seconds: 6),
      );
      if (!mounted) return;
      final role = (profile?['role'] ?? profile?['Role'] ?? '')
          .toString()
          .toLowerCase();
      if (role != 'coach') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      }
    } catch (_) {
      // Không redirect trên lỗi mạng — để user thấy app bình thường.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Consumer2<CoachBadgeProvider, CoachReportProvider>(
        builder: (context, badgeProvider, reportProvider, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Học viên',
                      iconData: Icons.groups_outlined,
                      activeIconData: Icons.groups_rounded,
                      badgeCount: badgeProvider.pendingCount,
                      badgeColor: const Color(0xFFE65100),
                    ),
                    _buildNavItem(
                      index: 1,
                      label: 'Lộ trình',
                      iconData: Icons.restaurant_menu_outlined,
                      activeIconData: Icons.restaurant_menu_rounded,
                      badgeCount: badgeProvider.pendingMealPlanCount,
                      badgeColor: const Color(0xFFE65100),
                    ),
                    _buildNavItem(
                      index: 2,
                      label: 'Báo cáo',
                      iconData: Icons.bar_chart_outlined,
                      activeIconData: Icons.bar_chart_rounded,
                      badgeCount: reportProvider.pendingCount,
                      badgeColor: const Color(0xFFD97706),
                    ),
                    _buildNavItem(
                      index: 3,
                      label: 'Thông báo',
                      iconData: Icons.notifications_none_rounded,
                      activeIconData: Icons.notifications_rounded,
                      badgeCount: badgeProvider.unreadNotifCount,
                      badgeColor: const Color(0xFFEF4444),
                    ),
                    _buildNavItem(
                      index: 4,
                      label: 'Cá nhân',
                      iconData: Icons.person_outline_rounded,
                      activeIconData: Icons.person_rounded,
                      badgeCount: 0,
                      badgeColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData iconData,
    required IconData activeIconData,
    required int badgeCount,
    required Color badgeColor,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = _coachPrimary;
    final inactiveColor = Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        splashColor: activeColor.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isSelected ? activeIconData : iconData,
                      size: 23,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade600,
                  letterSpacing: -0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachProfileLoadError extends StatelessWidget {
  const _CoachProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải hồ sơ PT',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: _coachPrimary,
                minimumSize: const Size(150, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Học viên ──────────────────────────────────────────────────────────
class _CoachClientsTab extends StatefulWidget {
  const _CoachClientsTab();

  @override
  State<_CoachClientsTab> createState() => _CoachClientsTabState();
}

class _CoachClientsTabState extends State<_CoachClientsTab> {
  final _repo = AdvancedRepository();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  int _clientsPage = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _clientsPage = 0);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _clients;
    return _clients.where((client) {
      final name = (client['fullName']?.toString() ?? '').toLowerCase();
      final email = (client['email']?.toString() ?? '').toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _repo.clients();
      if (!mounted) return;
      final pending = data
          .where((c) => (c['connectionStatus']?.toString() ?? '') == 'Pending')
          .toList();
      setState(() {
        _clients = data
            .where(
              (c) => (c['connectionStatus']?.toString() ?? '') == 'Connected',
            )
            .toList();
        _pending = pending;
        _loading = false;
      });
      // Update badge count via Provider
      if (mounted) {
        context.read<CoachBadgeProvider>().setPendingCount(pending.length);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String connectionId, String action) async {
    try {
      await _repo.approveClient(connectionId, action == 'accept');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClients;
    const pageSize = 6;
    final totalPages = (filtered.length / pageSize).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: _coachPrimary,
          child: CustomScrollView(
            slivers: [
              // Header section với gradient card & PT Status
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF135A37), Color(0xFF1A7A4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1A7A4A,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.sports_gymnastics_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Không gian PT',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4ADE80),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Quản lý & đồng hành cùng học viên',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _coachPrimary),
                  ),
                )
              else ...[
                // Stat Summary Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard(
                          'Học viên',
                          _clients.length.toString(),
                          Icons.people_alt_rounded,
                          _coachPrimary,
                          const Color(0xFFE8F5E9),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Chờ duyệt',
                          _pending.length.toString(),
                          Icons.pending_actions_rounded,
                          const Color(0xFFE65100),
                          const Color(0xFFFFF3E0),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Pending Requests Section
                if (_pending.isNotEmpty) ...[
                  _sectionHeader(
                    'Yêu cầu chờ duyệt',
                    _pending.length,
                    Icons.mark_email_unread_rounded,
                    const Color(0xFFE65100),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _pendingCard(_pending[i]),
                      childCount: _pending.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                // Managed Trainees Section & Search Bar
                _sectionHeader(
                  'Học viên đang quản lý',
                  _clients.length,
                  Icons.groups_rounded,
                  _coachPrimary,
                ),

                if (_clients.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tìm học viên theo tên, email...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _coachPrimary,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_clients.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _coachPrimary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_search_rounded,
                              size: 48,
                              color: _coachPrimary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Chưa có học viên nào',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Danh sách học viên sẽ hiển thị tại đây khi các học viên gửi yêu cầu liên kết với bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 44,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Không tìm thấy học viên khớp với "${_searchController.text}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final index = _clientsPage * pageSize + i;
                        if (index >= filtered.length) {
                          return const SizedBox.shrink();
                        }
                        return _clientCard(filtered[index]);
                      },
                      childCount: (filtered.length - _clientsPage * pageSize)
                          .clamp(0, pageSize),
                    ),
                  ),
                  if (filtered.length > pageSize)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: _clientsPage > 0
                                  ? () => setState(() => _clientsPage--)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _clientsPage > 0
                                      ? Colors.white
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _clientsPage > 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 20,
                                  color: _clientsPage > 0
                                      ? _coachPrimary
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Trang ${_clientsPage + 1} / $totalPages',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap:
                                  (_clientsPage + 1) * pageSize <
                                      filtered.length
                                  ? () => setState(() => _clientsPage++)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      (_clientsPage + 1) * pageSize <
                                          filtered.length
                                      ? Colors.white
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow:
                                      (_clientsPage + 1) * pageSize <
                                          filtered.length
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color:
                                      (_clientsPage + 1) * pageSize <
                                          filtered.length
                                      ? _coachPrimary
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgTint,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard(Map<String, dynamic> req) {
    final name =
        req['fullName']?.toString() ?? req['email']?.toString() ?? 'Học viên';
    final id = req['clientId']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'H',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 13,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Muốn liên kết với bạn',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _respond(id, 'accept'),
              icon: const Icon(Icons.check_rounded, size: 15),
              label: const Text(
                'Duyệt',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _coachPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () => _respond(id, 'reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Từ chối',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientCard(Map<String, dynamic> client) {
    final name =
        client['fullName']?.toString() ??
        client['email']?.toString() ??
        'Học viên';
    final email = client['email']?.toString() ?? '';
    final clientId = client['clientId']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoachClientDetailScreen(
                client: {
                  'clientId': clientId,
                  'clientName': name,
                  'email': email,
                },
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: _coachPrimary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF135A37), Color(0xFF1A7A4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'H',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: clientId.isEmpty
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoachChatScreen(
                              partnerId: clientId,
                              partnerName: name,
                            ),
                          ),
                        ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: _coachPrimary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab 2: Thông báo ─────────────────────────────────────────────────────────
class _CoachNotificationsTab extends StatefulWidget {
  const _CoachNotificationsTab({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<_CoachNotificationsTab> createState() => _CoachNotificationsTabState();
}

class _CoachNotificationsTabState extends State<_CoachNotificationsTab>
    with WidgetsBindingObserver {
  final _repo = NotificationRepository();
  final _realtime = RealtimeNotificationService();
  List<Map<String, dynamic>> _notis = [];
  bool _loading = true;
  Timer? _refreshTimer;
  StreamSubscription<AppNotification>? _realtimeNotifSub;
  StreamSubscription<int>? _realtimeCountSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // Đảm bảo realtime connection đã được start. NotificationProvider ở main.dart
    // cũng gọi start() nhưng có thể dispose nếu Provider bị unmount. Đảm bảo gọi
    // lại tại đây để tab Coach luôn nhận SignalR push.
    _realtime.start();
    _subscribeRealtime();
    // Auto refresh mỗi 60s — fix bug "Coach không thấy thông báo học viên đăng ký"
    // khi student gửi request sau khi Coach đã mở tab Thông báo.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _load(silent: true),
    );
  }

  void _subscribeRealtime() {
    _realtimeNotifSub = _realtime.notifications.listen((notification) {
      if (!mounted) return;
      _onRealtimeNotification(notification);
      if (notification.normalizedType == 'weekly_report_submitted') {
        unawaited(context.read<CoachReportProvider>().refresh());
      }
    });
    _realtimeCountSub = _realtime.unreadCounts.listen((count) {
      if (!mounted) return;
      context.read<CoachBadgeProvider>().setUnreadNotifCount(count);
    });
  }

  void _onRealtimeNotification(AppNotification notification) {
    // Dedupe theo id — tránh hiển thị trùng khi SignalR push lại hoặc khi
    // _load() silent cũng pick notification này sau đó.
    final exists = _notis.any(
      (n) =>
          (n['notifId']?.toString() ?? n['id']?.toString()) == notification.id,
    );
    if (exists) return;

    setState(() {
      _notis.insert(0, {
        'id': notification.id,
        'title': notification.title,
        'body': notification.body,
        'type': notification.rawType,
        'actionUrl': notification.actionUrl,
        'isRead': notification.isRead,
        'createdAt': notification.createdAt.toIso8601String(),
        'source': 'realtime',
        'notifId': notification.id,
        'displayTitle': notification.displayTitle,
        'displayBody': notification.displayBody,
      });
    });
    // Cập nhật badge ngay khi có notification mới qua SignalR — user mở app
    // không cần vào tab Thông báo mới biết có notif mới.
    _syncBadges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realtimeNotifSub?.cancel();
    _realtimeCountSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int get _unreadCount =>
      _notis.where((n) => n['isRead'] != true && n['IsRead'] != true).length;

  int get _unreadRouteCount => _notis.where((n) {
    final isUnread = n['isRead'] != true && n['IsRead'] != true;
    return isUnread && _normalizeType(n['type']) == 'pt_review_request';
  }).length;

  String _normalizeType(dynamic value) =>
      (value ?? '').toString().trim().toLowerCase().replaceAll('-', '_');

  void _syncBadges() {
    if (!mounted) return;
    final badges = context.read<CoachBadgeProvider>();
    badges.setUnreadNotifCount(_unreadCount);
    badges.setPendingMealPlanCount(_unreadRouteCount);
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = true);
    try {
      final notifications = await _repo.getNotifications(pageSize: 50);

      if (!mounted) return;

      final List<Map<String, dynamic>> allNotis = [];
      for (final n in notifications) {
        allNotis.add({
          'id': n.id,
          'title': n.title,
          'body': n.body,
          'type': n.rawType,
          'actionUrl': n.actionUrl,
          'isRead': n.isRead,
          'createdAt': n.createdAt.toIso8601String(),
          'source': 'notification',
          'notifId': n.id,
          'displayTitle': n.displayTitle,
          'displayBody': n.displayBody,
        });
      }

      allNotis.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.now();
        final bTime =
            DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _notis = allNotis;
        _loading = false;
      });
      // Update badge count via Provider
      if (mounted) {
        _syncBadges();
      }
    } catch (e) {
      debugPrint('[Notifications] Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    final matchingIndexes = <int>[];
    for (var i = 0; i < _notis.length; i++) {
      final notifId =
          _notis[i]['notifId']?.toString() ?? _notis[i]['id']?.toString();
      if (notifId == id) matchingIndexes.add(i);
    }
    if (matchingIndexes.isEmpty) return;

    setState(() {
      for (final index in matchingIndexes) {
        _notis[index]['isRead'] = true;
        _notis[index]['IsRead'] = true;
      }
    });
    _syncBadges();

    try {
      final success = await _repo.markAsRead(id);
      if (!success && mounted) {
        setState(() {
          for (final index in matchingIndexes) {
            if (index >= _notis.length) continue;
            _notis[index]['isRead'] = false;
            _notis[index]['IsRead'] = false;
          }
        });
        _syncBadges();
      }
    } catch (e) {
      debugPrint('[Notifications] Mark read error: $e');
      if (!mounted) return;
      setState(() {
        for (final index in matchingIndexes) {
          if (index >= _notis.length) continue;
          _notis[index]['isRead'] = false;
          _notis[index]['IsRead'] = false;
        }
      });
      _syncBadges();
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _coachPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: _coachPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a2e1f),
                          ),
                        ),
                        Text(
                          'Yêu cầu từ học viên',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (_notis.any(
                    (n) => n['isRead'] != true && n['IsRead'] != true,
                  ))
                    TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _repo.markAllAsRead();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Đã đánh dấu tất cả là đã đọc'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          debugPrint(
                            '[_CoachNotificationsTab] markAll error: $e',
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Không thể đánh dấu: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                        await _load();
                      },
                      child: const Text(
                        'Đọc tất cả',
                        style: TextStyle(fontSize: 12, color: _coachPrimary),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _coachPrimary),
                    )
                  : _notis.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có thông báo nào',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thông báo từ học viên sẽ hiển thị ở đây',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _coachPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _notis.length,
                        itemBuilder: (_, i) {
                          final n = _notis[i];
                          final isRead =
                              n['isRead'] == true || n['IsRead'] == true;
                          final title =
                              n['displayTitle']?.toString() ??
                              n['title']?.toString() ??
                              'Thông báo mới';
                          final body =
                              n['displayBody']?.toString() ??
                              n['body']?.toString() ??
                              '';
                          final createdAt = n['createdAt'] ?? n['CreatedAt'];
                          final notificationType = _normalizeType(n['type']);
                          final statusLabel = switch (notificationType) {
                            'pt_review_request' => 'Chờ duyệt',
                            'meal_plan_approved' => 'Đã duyệt',
                            'pt_route_approval' => 'Đã duyệt',
                            'coach_personal_program' => 'Lộ trình mới',
                            'weekly_report_submitted' => 'Cần đánh giá',
                            'weekly_report_pending' => 'Chờ PT đánh giá',
                            'weekly_report_reviewed' => 'Đã đánh giá',
                            _ => null,
                          };
                          final timeStr = createdAt != null
                              ? _formatTime(
                                  DateTime.tryParse(createdAt.toString()) ??
                                      DateTime.now(),
                                )
                              : 'Vừa xong';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () async {
                                final notifId = n['notifId']?.toString();
                                if (notifId != null && !isRead) {
                                  unawaited(_markRead(notifId));
                                }
                                if (notificationType == 'coach_chat_message') {
                                  final notification = AppNotification.fromJson(
                                    n,
                                  );
                                  await NotificationHandler()
                                      .handleAppNotificationTap(
                                        context,
                                        notification,
                                      );
                                } else if (notificationType ==
                                    'pt_review_request') {
                                  widget.onOpenTab(1);
                                } else if (notificationType ==
                                    'weekly_report_submitted') {
                                  final actionUrl =
                                      n['actionUrl']?.toString() ?? '';
                                  const prefix = 'coach_weekly_report:';
                                  if (actionUrl.startsWith(prefix)) {
                                    final reportId = actionUrl.substring(
                                      prefix.length,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CoachReportDetailScreen(
                                          reportId: reportId,
                                        ),
                                      ),
                                    );
                                  } else {
                                    widget.onOpenTab(2);
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? Colors.white
                                      : _coachPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: isRead
                                      ? null
                                      : Border.all(
                                          color: _coachPrimary.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _coachPrimary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.notifications,
                                        color: _coachPrimary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (body.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          if (statusLabel != null) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: const TextStyle(
                                                  color: Colors.deepOrange,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Text(
                                            timeStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: _coachPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Hồ sơ PT ─────────────────────────────────────────────────────────
class _CoachProfileTab extends StatefulWidget {
  const _CoachProfileTab();

  @override
  State<_CoachProfileTab> createState() => _CoachProfileTabState();
}

class _CoachProfileTabState extends State<_CoachProfileTab> {
  final _profileRepo = ProfileRepository();
  final _advancedRepo = AdvancedRepository();
  final _applicationRepo = CoachApplicationRepository();
  final _tokenStorage = TokenStorage();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _coachProfile;
  List<Map<String, dynamic>> _clients = [];
  String _email = '';
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _load();
  }

  Future<void> _loadEmail() async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final email = JwtUtils.tryGetEmail(token);
      if (email != null && mounted) {
        setState(() => _email = email);
      }
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profileData = await _profileRepo.getMyProfile();
      final myCoach = await _applicationRepo.getMine();
      final clients = await _advancedRepo.clients();

      if (mounted) {
        setState(() {
          _profile = profileData;
          _coachProfile = myCoach;
          _clients = clients;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[_CoachProfileTab] Load error: $e');
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _email.isNotEmpty
        ? _email
        : (_coachProfile?['email'] ??
                  _profile?['email'] ??
                  _profile?['Email'] ??
                  '')
              .toString();
    final connectedClients = _clients
        .where(
          (client) =>
              (client['connectionStatus']?.toString() ?? '').toLowerCase() ==
              'connected',
        )
        .length;
    final pendingClients = _clients
        .where(
          (client) =>
              (client['connectionStatus']?.toString() ?? '').toLowerCase() ==
              'pending',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _coachPrimary),
              )
            : _loadError != null
            ? _CoachProfileLoadError(message: _loadError!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                color: _coachPrimary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    CoachProfileOverview(
                      profile: _coachProfile ?? const {},
                      email: email,
                      connectedClients: connectedClients,
                      pendingClients: pendingClients,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _coachProfile == null
                            ? null
                            : () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CoachApplicationScreen(
                                      initialData: _coachProfile,
                                      editMode: true,
                                    ),
                                  ),
                                );
                                if (result == true) _load();
                              },
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa hồ sơ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _coachPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(color: Colors.red, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _logout() async {
    await _profileRepo.logout();
    OnboardingGate.clearSessionComplete();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    }
  }
}

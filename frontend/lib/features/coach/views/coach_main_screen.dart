import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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
import 'coach_profile_edit_screen.dart';

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
      backgroundColor: const Color(0xFFF0F7F4),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Consumer2<CoachBadgeProvider, CoachReportProvider>(
        builder: (context, badgeProvider, reportProvider, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _selectTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 10,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(
                icon: _badgedIcon(
                  iconData: Icons.people_outline,
                  count: badgeProvider.pendingCount,
                  badgeColor: Colors.orange,
                ),
                activeIcon: _badgedIcon(
                  iconData: Icons.people,
                  count: badgeProvider.pendingCount,
                  badgeColor: Colors.orange,
                ),
                label: 'Học viên',
              ),
              BottomNavigationBarItem(
                icon: _badgedIcon(
                  iconData: Icons.restaurant_menu_outlined,
                  count: badgeProvider.pendingMealPlanCount,
                  badgeColor: Colors.orange,
                ),
                activeIcon: _badgedIcon(
                  iconData: Icons.restaurant_menu,
                  count: badgeProvider.pendingMealPlanCount,
                  badgeColor: Colors.orange,
                ),
                label: 'Lộ trình',
              ),
              BottomNavigationBarItem(
                icon: _badgedIcon(
                  iconData: Icons.assessment_outlined,
                  count: reportProvider.pendingCount,
                  badgeColor: Colors.deepOrange,
                ),
                activeIcon: _badgedIcon(
                  iconData: Icons.assessment,
                  count: reportProvider.pendingCount,
                  badgeColor: Colors.deepOrange,
                ),
                label: 'Báo cáo',
              ),
              BottomNavigationBarItem(
                icon: _badgedIcon(
                  iconData: Icons.notifications_none_outlined,
                  count: badgeProvider.unreadNotifCount,
                  badgeColor: Colors.red,
                ),
                activeIcon: _badgedIcon(
                  iconData: Icons.notifications,
                  count: badgeProvider.unreadNotifCount,
                  badgeColor: Colors.red,
                ),
                label: 'Thông báo',
              ),
              const BottomNavigationBarItem(
                icon: SizedBox(
                  height: 44,
                  child: Icon(Icons.person_outline, size: 24),
                ),
                activeIcon: SizedBox(
                  height: 44,
                  child: Icon(Icons.person, size: 24),
                ),
                label: 'Cá nhân',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badgedIcon({
    required IconData iconData,
    required int count,
    required Color badgeColor,
  }) {
    return SizedBox(
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(iconData, size: 24),
          if (count > 0)
            Positioned(
              right: -6,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
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
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  int _clientsPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: _coachPrimary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
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
                          Icons.sports,
                          color: _coachPrimary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Không gian PT',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a2e1f),
                            ),
                          ),
                          Text(
                            'Quản lý học viên của bạn',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard(
                          'Học viên',
                          _clients.length.toString(),
                          Icons.people,
                          _coachPrimary,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Chờ duyệt',
                          _pending.length.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_pending.isNotEmpty) ...[
                  _sectionHeader(
                    'Yêu cầu chờ duyệt',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _pendingCard(_pending[i]),
                      childCount: _pending.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
                _sectionHeader(
                  'Học viên đang quản lý',
                  Icons.people,
                  _coachPrimary,
                ),
                if (_clients.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có học viên nào\nHọc viên sẽ hiện ở đây khi được liên kết.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final index = _clientsPage * 6 + i;
                        if (index >= _clients.length) return const SizedBox.shrink();
                        return _clientCard(_clients[index]);
                      },
                      childCount: (_clients.length - _clientsPage * 6).clamp(0, 6),
                    ),
                  ),
                  if (_clients.length > 6)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                              onPressed: _clientsPage > 0
                                  ? () => setState(() => _clientsPage--)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Trang ${_clientsPage + 1} / ${(_clients.length / 6).ceil()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              onPressed: (_clientsPage + 1) * 6 < _clients.length
                                  ? () => setState(() => _clientsPage++)
                                  : null,
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'H',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Muốn liên kết với bạn',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _respond(id, 'accept'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _coachPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Chấp nhận', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => _respond(id, 'reject'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _coachPrimary.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _coachPrimary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'H',
                  style: const TextStyle(
                    color: _coachPrimary,
                    fontWeight: FontWeight.bold,
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
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Nhắn tin với học viên',
                onPressed: clientId.isEmpty
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
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: _coachPrimary,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
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
  final _tokenStorage = TokenStorage();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _coachProfile;
  List<Map<String, dynamic>> _clients = [];
  String _email = '';
  bool _loading = true;

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
    setState(() => _loading = true);
    try {
      final profileData = await _profileRepo.getMyProfile();
      // Get coach profile from coaches endpoint
      final coaches = await _advancedRepo.coaches();
      final coachId =
          profileData?['id']?.toString() ?? profileData?['Id']?.toString();
      Map<String, dynamic>? myCoach;
      if (coachId != null) {
        myCoach = coaches.firstWhere(
          (c) =>
              c['userId']?.toString() == coachId ||
              c['id']?.toString() == coachId,
          orElse: () => {},
        );
      }
      // Get my clients for stats
      final clients = await _advancedRepo.clients();

      if (mounted) {
        setState(() {
          _profile = profileData;
          _coachProfile = (myCoach?.isNotEmpty ?? false) ? myCoach : null;
          _clients = clients;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[_CoachProfileTab] Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (_profile?['fullName'] ?? _profile?['FullName'] ?? 'PT / Coach')
            .toString();
    final email = _email.isNotEmpty
        ? _email
        : (_profile?['email'] ?? _profile?['Email'] ?? '').toString();
    final role = _translateRole(_profile?['role']?.toString() ?? 'Coach');

    // Gender
    final genderRaw = (_profile?['gender'] ?? _profile?['Gender'] ?? '')
        .toString();
    final gender = _translateGender(genderRaw);

    // Date of birth
    final dobRaw = (_profile?['dateOfBirth'] ?? _profile?['DateOfBirth'] ?? '')
        .toString();
    final dateOfBirth = _formatDate(dobRaw);

    // Coach specific info
    final specialty =
        (_coachProfile?['specialty'] ?? _coachProfile?['Specialty'] ?? '')
            .toString();
    final bio = (_coachProfile?['bio'] ?? _coachProfile?['Bio'] ?? '')
        .toString();
    final experience =
        (_coachProfile?['experienceYears'] ??
                _coachProfile?['ExperienceYears'] ??
                0)
            .toString();
    final certificateUrl =
        (_coachProfile?['certificateUrl'] ??
                _coachProfile?['CertificateUrl'] ??
                '')
            .toString();

    // Stats
    final connectedClients = _clients
        .where((c) => (c['connectionStatus']?.toString() ?? '') == 'Connected')
        .length;
    final pendingClients = _clients
        .where((c) => (c['connectionStatus']?.toString() ?? '') == 'Pending')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _coachPrimary),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: _coachPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header Profile Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a7a4a), Color(0xFF2ecc71)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _coachPrimary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🏅 ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  role,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people,
                            value: '$connectedClients',
                            label: 'Học viên',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.pending_actions,
                            value: '$pendingClients',
                            label: 'Chờ duyệt',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.work_history,
                            value: experience,
                            label: 'Năm kinh nghiệm',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Thông tin cá nhân
                    _buildSectionHeader('Thông tin cá nhân', Icons.person),
                    const SizedBox(height: 10),
                    _buildInfoCard([
                      _infoItem(
                        Icons.email_outlined,
                        'Email',
                        email.isEmpty ? 'Chưa cập nhật' : email,
                      ),
                      _infoItem(
                        Icons.wc_outlined,
                        'Giới tính',
                        gender.isEmpty ? 'Chưa cập nhật' : gender,
                      ),
                      _infoItem(
                        Icons.cake_outlined,
                        'Ngày sinh',
                        dateOfBirth.isEmpty ? 'Chưa cập nhật' : dateOfBirth,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Thông tin Coach/PT
                    if (_coachProfile != null && _coachProfile!.isNotEmpty) ...[
                      _buildSectionHeader('Thông tin Coach/PT', Icons.sports),
                      const SizedBox(height: 10),
                      _buildInfoCard([
                        _infoItem(
                          Icons.star_outline,
                          'Chuyên môn',
                          specialty.isEmpty ? 'Chưa cập nhật' : specialty,
                        ),
                        if (bio.isNotEmpty)
                          _infoItem(
                            Icons.description_outlined,
                            'Giới thiệu',
                            bio,
                            maxLines: 3,
                          ),
                        if (certificateUrl.isNotEmpty)
                          _infoItem(
                            Icons.verified_outlined,
                            'Chứng chỉ',
                            'Đã xác minh',
                          ),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // Nút hành động
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CoachProfileEditScreen(),
                            ),
                          );
                          if (result == true) _load();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa hồ sơ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _coachPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _coachPrimary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a2e1f),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final index = items.indexOf(item);
          return Column(
            children: [
              item,
              if (index < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _coachPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _translateRole(String? role) {
    if (role == null) return 'Coach';
    final r = role.toLowerCase();
    if (r == 'coach') return 'Coach / HLV Dinh dưỡng';
    if (r == 'admin') return 'Quản trị viên';
    if (r == 'gymer') return 'Gymer';
    if (r == 'user') return 'Người dùng';
    return role;
  }

  String _translateGender(String? gender) {
    if (gender == null || gender.isEmpty) return '';
    final g = gender.toLowerCase();
    if (g == 'male') return 'Nam';
    if (g == 'female') return 'Nữ';
    if (g == 'other') return 'Khác';
    return gender;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr.split('T').first);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
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

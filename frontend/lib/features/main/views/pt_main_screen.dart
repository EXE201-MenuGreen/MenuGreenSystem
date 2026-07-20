import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../advanced/views/advanced_detail_screens.dart';
import '../../auth/views/welcome_screen.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../advanced/repositories/advanced_repository.dart';

// ─── PT Main Shell ────────────────────────────────────────────────────────────
class PtMainScreen extends StatefulWidget {
  const PtMainScreen({super.key});

  @override
  State<PtMainScreen> createState() => _PtMainScreenState();
}

class _PtMainScreenState extends State<PtMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _PtClientsTab(),
    _PtNotificationsTab(),
    _PtProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: SizedBox(height: 44, child: Icon(Icons.people_outline, size: 24)),
            activeIcon: SizedBox(height: 44, child: Icon(Icons.people, size: 24)),
            label: 'Học viên',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(height: 44, child: Icon(Icons.notifications_none_outlined, size: 24)),
            activeIcon: SizedBox(height: 44, child: Icon(Icons.notifications, size: 24)),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(height: 44, child: Icon(Icons.person_outline, size: 24)),
            activeIcon: SizedBox(height: 44, child: Icon(Icons.person, size: 24)),
            label: 'Hồ sơ PT',
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Học viên ──────────────────────────────────────────────────────────
class _PtClientsTab extends StatefulWidget {
  const _PtClientsTab();

  @override
  State<_PtClientsTab> createState() => _PtClientsTabState();
}

class _PtClientsTabState extends State<_PtClientsTab> {
  final _repo = AdvancedRepository();
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;

  static const Color _primary = Color(0xFF1a7a4a);

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
      setState(() {
        _clients = data.where((c) =>
            (c['connectionStatus']?.toString() ?? '') == 'Connected').toList();
        _pending = data.where((c) =>
            (c['connectionStatus']?.toString() ?? '') == 'Pending').toList();
        _loading = false;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
          color: _primary,
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
                          color: _primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.sports, color: _primary, size: 26),
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
                  child: Center(child: CircularProgressIndicator(color: _primary)),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard('Học viên', _clients.length.toString(), Icons.people, _primary),
                        const SizedBox(width: 12),
                        _statCard('Chờ duyệt', _pending.length.toString(), Icons.pending_actions, Colors.orange),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_pending.isNotEmpty) ...[
                  _sectionHeader('Yêu cầu chờ duyệt', Icons.pending_actions, Colors.orange),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _pendingCard(_pending[i]),
                      childCount: _pending.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
                _sectionHeader('Học viên đang quản lý', Icons.people, _primary),
                if (_clients.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
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
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _clientCard(_clients[i]),
                      childCount: _clients.length,
                    ),
                  ),
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
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
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
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard(Map<String, dynamic> req) {
    final name = req['fullName']?.toString() ?? req['email']?.toString() ?? 'Học viên';
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
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'H',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Muốn liên kết với bạn', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _respond(id, 'accept'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final name = client['fullName']?.toString() ?? client['email']?.toString() ?? 'Học viên';
    final email = client['email']?.toString() ?? '';
    final clientId = client['clientId']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachClientDetailScreen(client: {
              'clientId': clientId,
              'clientName': name,
              'email': email,
            }),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _primary.withValues(alpha: 0.12),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'H',
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (email.isNotEmpty)
                      Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
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
class _PtNotificationsTab extends StatefulWidget {
  const _PtNotificationsTab();

  @override
  State<_PtNotificationsTab> createState() => _PtNotificationsTabState();
}

class _PtNotificationsTabState extends State<_PtNotificationsTab> {
  final _repo = AdvancedRepository();
  List<Map<String, dynamic>> _notis = [];
  bool _loading = true;

  static const Color _primary = Color(0xFF1a7a4a);

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
      setState(() {
        _notis = data.where((c) =>
            (c['connectionStatus']?.toString() ?? '') == 'Connected').map((c) => {
          'title': 'Học viên ${c['fullName'] ?? c['email']} đã gửi lộ trình tuần',
          'clientId': c['clientId']?.toString() ?? '',
          'clientName': c['fullName'] ?? c['email'] ?? '',
          'isRead': false,
          'time': 'Hôm nay',
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications, color: _primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông báo',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a2e1f))),
                      Text('Cập nhật từ học viên của bạn',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : _notis.isEmpty
                      ? const Center(
                          child: Text('Chưa có thông báo nào', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _notis.length,
                            itemBuilder: (_, i) {
                              final n = _notis[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _notis[i]['isRead'] = true);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CoachClientDetailScreen(client: {
                                          'clientId': n['clientId'].toString(),
                                          'clientName': n['clientName'].toString(),
                                        }),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: n['isRead'] == true
                                          ? Colors.white
                                          : _primary.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: n['isRead'] == true
                                          ? null
                                          : Border.all(color: _primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.assignment, color: _primary, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n['title'].toString(),
                                                style: TextStyle(
                                                  fontWeight: n['isRead'] == true
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(n['time'].toString(),
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        if (n['isRead'] != true)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
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
class _PtProfileTab extends StatefulWidget {
  const _PtProfileTab();

  @override
  State<_PtProfileTab> createState() => _PtProfileTabState();
}

class _PtProfileTabState extends State<_PtProfileTab> {
  final _profileRepo = ProfileRepository();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  static const Color _primary = Color(0xFF1a7a4a);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _profileRepo.getMyProfile();
    if (mounted) setState(() { _profile = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile?['fullName'] ?? _profile?['FullName'] ?? 'PT / Coach').toString();
    final email = (_profile?['email'] ?? _profile?['Email'] ?? '').toString();
    final role = (_profile?['role'] ?? 'Coach').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1a7a4a), Color(0xFF2ecc71)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(name,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('\ud83c\udfcb\ufe0f $role',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _infoItem(Icons.email_outlined, 'Email', email),
                  _infoItem(Icons.badge_outlined, 'Vai trò', role),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Đăng xuất',
                          style: TextStyle(color: Colors.red, fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: _primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
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

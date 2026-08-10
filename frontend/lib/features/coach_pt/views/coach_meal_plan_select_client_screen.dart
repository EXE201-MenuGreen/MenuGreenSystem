import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../coach_pt.dart';
import 'coach_meal_plan_history_screen.dart';

/// Entry screen for the Coach's "Lộ trình" tab. Lists all connected
/// Gymers with search & pagination so the Coach can pick one to manage.
class _ClientScreenData {
  final List<Map<String, dynamic>> clients;
  final Map<String, int> pendingRouteCounts;
  _ClientScreenData({required this.clients, required this.pendingRouteCounts});
}

class CoachMealPlanSelectClientScreen extends StatefulWidget {
  const CoachMealPlanSelectClientScreen({super.key});

  @override
  State<CoachMealPlanSelectClientScreen> createState() =>
      _CoachMealPlanSelectClientScreenState();
}

class _CoachMealPlanSelectClientScreenState
    extends State<CoachMealPlanSelectClientScreen> {
  final AdvancedRepository _repo = AdvancedRepository();
  late Future<_ClientScreenData> _dataFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  int _currentPage = 0;
  static const int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_ClientScreenData> _loadData() async {
    final raw = await _repo.clients();
    final connected = raw
        .where(
          (c) =>
              (c['connectionStatus'] ?? c['ConnectionStatus']) == 'Connected',
        )
        .toList();

    final pendingCounts = <String, int>{};
    for (final client in connected) {
      final clientId = (client['clientId'] ?? client['ClientId'])?.toString();
      final rawCount =
          client['pendingRouteApprovalCount'] ??
          client['PendingRouteApprovalCount'];
      final count = rawCount is num
          ? rawCount.toInt()
          : int.tryParse(rawCount?.toString() ?? '') ?? 0;
      if (clientId != null && clientId.isNotEmpty && count > 0) {
        pendingCounts[clientId] = count;
      }
    }
    connected.sort((a, b) {
      final aId = (a['clientId'] ?? a['ClientId'])?.toString() ?? '';
      final bId = (b['clientId'] ?? b['ClientId'])?.toString() ?? '';
      return (pendingCounts[bId] ?? 0).compareTo(pendingCounts[aId] ?? 0);
    });

    return _ClientScreenData(
      clients: connected,
      pendingRouteCounts: pendingCounts,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Chọn học viên',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<_ClientScreenData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: _localize(snapshot.error.toString()),
                onRetry: _refresh,
              );
            }
            final data =
                snapshot.data ??
                _ClientScreenData(clients: [], pendingRouteCounts: {});
            final allClients = data.clients;
            final pendingCounts = data.pendingRouteCounts;
            final pendingIds = pendingCounts.keys.toSet();

            if (allClients.isEmpty) {
              return const _EmptyState(
                icon: Icons.people_outline_rounded,
                message: 'Bạn chưa có học viên nào đang kết nối.',
              );
            }

            // Filter search query
            final filteredClients = allClients.where((c) {
              final name =
                  (c['fullName'] ??
                          c['FullName'] ??
                          c['email'] ??
                          c['Email'] ??
                          '')
                      .toString()
                      .toLowerCase();
              return name.contains(_searchQuery.toLowerCase());
            }).toList();

            final totalPages = (filteredClients.length / _itemsPerPage).ceil();
            final safePage = totalPages == 0
                ? 0
                : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);
            final pageClients = filteredClients
                .skip(safePage * _itemsPerPage)
                .take(_itemsPerPage)
                .toList();

            return Column(
              children: [
                // Header Banner Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF135A37), Color(0xFF1A7A4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A7A4A).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Lộ trình học viên',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                if (pendingIds.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${pendingIds.length} chờ duyệt',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Chọn học viên để quản lý & duyệt lộ trình',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD1FAE5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm học viên...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 0;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),

                // Client List
                Expanded(
                  child: pageClients.isEmpty
                      ? Center(
                          child: Text(
                            'Không tìm thấy học viên nào phù hợp',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: pageClients.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = pageClients[index];
                            final name =
                                (c['fullName'] ??
                                        c['FullName'] ??
                                        c['email'] ??
                                        c['Email'] ??
                                        'Học viên')
                                    .toString();
                            final clientId = (c['clientId'] ?? c['ClientId'])
                                .toString();
                            final avatar = (c['avatarUrl'] ?? c['AvatarUrl'])
                                ?.toString();
                            final email =
                                (c['email'] ?? c['Email'])?.toString() ?? '';
                            final hasPending = pendingIds.contains(clientId);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasPending
                                      ? const Color(0xFFFDE68A)
                                      : Colors.grey.shade200,
                                  width: hasPending ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: hasPending
                                        ? const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: hasPending ? 10 : 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider(
                                        create: (_) =>
                                            CoachMealPlanProvider()
                                              ..loadPlansForClient(clientId),
                                        child: CoachMealPlanHistoryScreen(
                                          clientId: clientId,
                                          clientName: name,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: hasPending
                                              ? const EdgeInsets.all(2)
                                              : EdgeInsets.zero,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: hasPending
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFFEA580C,
                                                    ),
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            backgroundImage:
                                                avatar != null &&
                                                    avatar.isNotEmpty
                                                ? NetworkImage(avatar)
                                                : null,
                                            child:
                                                avatar == null || avatar.isEmpty
                                                ? Text(
                                                    name.isNotEmpty
                                                        ? name[0].toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.primary,
                                                      fontSize: 16,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 15,
                                                        color: Color(
                                                          0xFF111827,
                                                        ),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (hasPending) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 7,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFFFF7ED,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFFFEDD5,
                                                          ),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.stars_rounded,
                                                            size: 13,
                                                            color: Color(
                                                              0xFFEA580C,
                                                            ),
                                                          ),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            'Mới gửi',
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: Color(
                                                                0xFFEA580C,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                email.isNotEmpty
                                                    ? email
                                                    : 'Quản lý lộ trình ăn uống',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Pagination Controls
                if (filteredClients.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 16,
                          ),
                          onPressed: safePage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trang ${safePage + 1} / $totalPages'
                          ' • ${filteredClients.length} học viên',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          onPressed: safePage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _localize(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final m = decoded['message'] ?? decoded['Message'];
      if (m != null) return m.toString();
    }
  } catch (_) {}
  return raw;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

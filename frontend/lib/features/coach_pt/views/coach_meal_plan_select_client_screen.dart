import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../coach_pt.dart';
import 'coach_meal_plan_history_screen.dart';

/// Entry screen for the Coach's "Lộ trình" tab. Lists all connected
/// Gymers with search & pagination so the Coach can pick one to manage.
class CoachMealPlanSelectClientScreen extends StatefulWidget {
  const CoachMealPlanSelectClientScreen({super.key});

  @override
  State<CoachMealPlanSelectClientScreen> createState() =>
      _CoachMealPlanSelectClientScreenState();
}

class _CoachMealPlanSelectClientScreenState
    extends State<CoachMealPlanSelectClientScreen> {
  final AdvancedRepository _repo = AdvancedRepository();
  late Future<List<Map<String, dynamic>>> _clientsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  int _currentPage = 0;
  static const int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _clientsFuture = _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadClients() async {
    final raw = await _repo.clients();
    return raw
        .where((c) => (c['connectionStatus'] ?? c['ConnectionStatus']) == 'Connected')
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _clientsFuture = _loadClients();
    });
    await _clientsFuture;
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _clientsFuture,
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
            final allClients = snapshot.data ?? const <Map<String, dynamic>>[];
            if (allClients.isEmpty) {
              return const _EmptyState(
                icon: Icons.people_outline_rounded,
                message: 'Bạn chưa có học viên nào đang kết nối.',
              );
            }

            // Filter search query
            final filteredClients = allClients.where((c) {
              final name = (c['fullName'] ??
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
                // Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
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
                          padding: const EdgeInsets.all(16),
                          itemCount: pageClients.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = pageClients[index];
                            final name = (c['fullName'] ??
                                    c['FullName'] ??
                                    c['email'] ??
                                    c['Email'] ??
                                    'Học viên')
                                .toString();
                            final clientId =
                                (c['clientId'] ?? c['ClientId']).toString();
                            final avatar =
                                (c['avatarUrl'] ?? c['AvatarUrl'])?.toString();
                            final email =
                                (c['email'] ?? c['Email'])?.toString() ?? '';

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
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
                                        create: (_) => CoachMealPlanProvider()
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
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          backgroundImage: avatar != null &&
                                                  avatar.isNotEmpty
                                              ? NetworkImage(avatar)
                                              : null,
                                          child: avatar == null || avatar.isEmpty
                                              ? Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                    fontSize: 16,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: Color(0xFF111827),
                                                ),
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
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.08),
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
                if (totalPages > 1)
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
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                          onPressed: safePage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trang ${safePage + 1} / $totalPages',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
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

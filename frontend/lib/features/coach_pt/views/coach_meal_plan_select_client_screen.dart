import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../advanced/repositories/advanced_repository.dart';
import '../coach_pt.dart';
import 'coach_meal_plan_history_screen.dart';

/// Entry screen for the Coach's "Lộ trình" tab. Lists all connected
/// Gymers so the Coach can pick one to manage their meal plans.
///
/// Tapping a Gymer pushes [CoachMealPlanHistoryScreen] for that client.
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

  @override
  void initState() {
    super.initState();
    _clientsFuture = _loadClients();
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
      appBar: AppBar(
        title: const Text('Chọn học viên'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _clientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: _localize(snapshot.error.toString()),
                onRetry: _refresh,
              );
            }
            final clients = snapshot.data ?? const <Map<String, dynamic>>[];
            if (clients.isEmpty) {
              return const _EmptyState(
                icon: Icons.people_outline,
                message: 'Bạn chưa có học viên nào đang kết nối.',
              );
            }
            return ListView.builder(
              itemCount: clients.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final c = clients[index];
                final name = (c['fullName'] ??
                        c['FullName'] ??
                        c['email'] ??
                        c['Email'] ??
                        'Học viên')
                    .toString();
                final clientId = (c['clientId'] ?? c['ClientId']).toString();
                final avatar =
                    (c['avatarUrl'] ?? c['AvatarUrl'])?.toString();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar == null || avatar.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  title: Text(name),
                  subtitle: Text('Quản lý lộ trình'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => CoachMealPlanProvider()..loadPlansForClient(clientId),
                        child: CoachMealPlanHistoryScreen(clientId: clientId, clientName: name),
                      ),
                    ),
                  ),
                );
              },
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
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

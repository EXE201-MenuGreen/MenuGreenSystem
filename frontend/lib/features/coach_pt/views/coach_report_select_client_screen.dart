import 'package:flutter/material.dart';

import '../../advanced/repositories/advanced_repository.dart';
import 'coach_reports_tab_screen.dart';

/// Re-usable entry screen for "Báo cáo của {Gymer}":
/// * push() from anywhere to scope the CoachReportsTabScreen to one Gymer.
///
/// Internally it just navigates the user to the same list view; the
/// client-scoped filter is currently best-effort (we hide non-matching
/// reports client-side). Backend scoping by [clientId] can be added later
/// by extending `coachWeeklyReports({clientId})` on the repository.
class CoachReportSelectClientScreen extends StatefulWidget {
  const CoachReportSelectClientScreen({super.key});

  @override
  State<CoachReportSelectClientScreen> createState() =>
      _CoachReportSelectClientScreenState();
}

class _CoachReportSelectClientScreenState
    extends State<CoachReportSelectClientScreen> {
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
        .where((c) =>
            (c['connectionStatus'] ?? c['ConnectionStatus']) == 'Connected')
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _clientsFuture = _loadClients());
    await _clientsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn học viên')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _clientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final clients = snapshot.data ?? const [];
            if (clients.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Bạn chưa có học viên nào đang kết nối.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final c = clients[index];
                final name = (c['fullName'] ??
                        c['FullName'] ??
                        c['email'] ??
                        c['Email'] ??
                        'Học viên')
                    .toString();
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.assignment)),
                  title: Text(name),
                  subtitle: const Text('Xem báo cáo tuần'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const CoachReportsTabScreen(),
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

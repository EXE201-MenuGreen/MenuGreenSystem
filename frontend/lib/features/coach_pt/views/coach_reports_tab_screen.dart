import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../coach_pt.dart';
import 'coach_report_detail_screen.dart';

/// Coach-side "Báo cáo" tab. Lists weekly reports across all connected
/// Gymers. Supports filter by week / month / status and a "client" sub-pick
/// via the icon button.
///
/// When [clientId] is provided, the dropdown to pick a different client is
/// hidden and the list is scoped to that Gymer only.
class CoachReportsTabScreen extends StatefulWidget {
  const CoachReportsTabScreen({super.key, this.clientId, this.clientName});

  /// When set, fetch reports only for this client.
  final String? clientId;

  /// Optional display name (used in the app bar).
  final String? clientName;

  @override
  State<CoachReportsTabScreen> createState() =>
      _CoachReportsTabScreenState();
}

class _CoachReportsTabScreenState extends State<CoachReportsTabScreen> {
  CoachReportStatus? _status;

  bool get _isClientScoped => (widget.clientId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CoachReportProvider>();
      provider.loadReports(
        status: _status,
        clientId: widget.clientId,
        resetFilters: false,
      );
    });
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
      helpText: 'Chọn một ngày trong tuần',
    );
    if (picked != null && mounted) {
      final monday = picked.subtract(Duration(days: picked.weekday - 1));
      await context.read<CoachReportProvider>().loadReports(
            weekStart: monday,
            status: _status,
            clientId: widget.clientId,
            resetFilters: false,
          );
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(2030),
      initialDate: now,
      helpText: 'Chọn một ngày trong tháng',
    );
    if (picked != null && mounted) {
      final m =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      await context.read<CoachReportProvider>().loadReports(
            month: m,
            status: _status,
            clientId: widget.clientId,
            resetFilters: false,
          );
    }
  }

  Future<void> _showFilters() async {
    final provider = context.read<CoachReportProvider>();
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Theo tuần'),
              onTap: () {
                Navigator.pop(ctx);
                _pickWeek();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Theo tháng'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMonth();
              },
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Tất cả'),
              onTap: () {
                Navigator.pop(ctx);
                provider.loadReports(
                  clientId: widget.clientId,
                  resetFilters: false,
                );
              },
            ),
            const Divider(height: 0),
            ...CoachReportStatus.values.map(
              (s) => ListTile(
                leading: Icon(
                  _status == s ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                ),
                title: Text(_statusLabel(s)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _status = s);
                  provider.loadReports(
                    status: s,
                    clientId: widget.clientId,
                    resetFilters: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isClientScoped && (widget.clientName ?? '').isNotEmpty
        ? 'Báo cáo tuần • ${widget.clientName}'
        : 'Báo cáo tuần';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: const _ReportsList(),
    );
  }
}

String _statusLabel(CoachReportStatus s) => switch (s) {
      CoachReportStatus.pending => 'Chờ duyệt',
      CoachReportStatus.reviewed => 'Đã review',
      CoachReportStatus.applied => 'Đã áp dụng',
      CoachReportStatus.rejected => 'Bị từ chối',
    };

class _ReportsList extends StatelessWidget {
  const _ReportsList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachReportProvider>();
    if (provider.isLoading && provider.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.reports.isEmpty) {
      return _ErrorState(
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }
    if (provider.reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.only(top: 120),
          children: const [
            Center(
              child: Icon(Icons.assignment_outlined,
                  size: 64, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có báo cáo nào.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        itemCount: provider.reports.length,
        itemBuilder: (context, index) {
          final r = provider.reports[index];
          return _ReportCard(report: r);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final CoachWeeklyReport report;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.assignment, color: Colors.white),
        ),
        title: Text(report.studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tuần: ${_fmt(report.weekStartDate)}'),
            if (report.checkInWeight != null)
              Text('Cân nặng: ${report.checkInWeight!.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: _StatusChip(status: report.status),
        onTap: () async {
          await context
              .read<CoachReportProvider>()
              .loadReportDetail(report.reportId);
          if (!context.mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CoachReportDetailScreen(reportId: report.reportId),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CoachReportStatus status;
  @override
  Widget build(BuildContext context) {
    final c = switch (status) {
      CoachReportStatus.pending => Colors.orange,
      CoachReportStatus.reviewed => Colors.blue,
      CoachReportStatus.applied => Colors.green,
      CoachReportStatus.rejected => Colors.red,
    };
    return Chip(
      backgroundColor: c.withValues(alpha: 0.15),
      side: BorderSide(color: c),
      label: Text(
        _statusLabel(status),
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
      ),
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
            Text(message, textAlign: TextAlign.center),
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

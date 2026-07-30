import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/advanced_repository.dart';
import '../utils/weekly_report_rules.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import 'advanced_detail_screens.dart';

class AdvancedFeaturesScreen extends StatelessWidget {
  const AdvancedFeaturesScreen({
    super.key,
    this.gymerOnly = false,
    this.initialIndex = 0,
    this.initialReportId,
  });

  final bool gymerOnly;
  final int initialIndex;
  final String? initialReportId;

  @override
  Widget build(BuildContext context) {
    final tabCount = gymerOnly ? 2 : 5;
    final safeInitialIndex = initialIndex.clamp(0, tabCount - 1);
    return DefaultTabController(
      length: tabCount,
      initialIndex: safeInitialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            gymerOnly ? 'Đồng hành Gym / PT' : 'Dịch vụ & quản lý',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: gymerOnly
                ? const [Tab(text: 'PT Review'), Tab(text: 'Huấn luyện viên')]
                : const [
                    Tab(text: 'PT Review'),
                    Tab(text: 'Ngân sách'),
                    Tab(text: 'Coach'),
                    Tab(text: 'Nguyên liệu'),
                    Tab(text: 'Người dùng'),
                  ],
          ),
        ),
        body: TabBarView(
          children: gymerOnly
              ? [
                  _PtTab(initialReportId: initialReportId),
                  const _CoachTab(gymerMode: true),
                ]
              : [
                  _PtTab(initialReportId: initialReportId),
                  const _BudgetTab(),
                  const _CoachTab(),
                  const _IngredientTab(),
                  const _UserTab(),
                ],
        ),
      ),
    );
  }
}

String _v(Map<String, dynamic> m, String key, [String fallback = '']) =>
    (m[key] ?? m[key[0].toUpperCase() + key.substring(1)] ?? fallback)
        .toString();
void _notice(BuildContext c, Object value) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(value.toString().replaceFirst('Exception: ', ''))),
    );

class _PtTab extends StatefulWidget {
  const _PtTab({this.initialReportId});

  final String? initialReportId;
  @override
  State<_PtTab> createState() => _PtTabState();
}

class _PtTabState extends State<_PtTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  bool _openedInitialReport = false;

  bool get _isSunday => canCreateWeeklyReportOn(DateTime.now());

  DateTime get _currentWeekMonday => weeklyReportWeekStart(DateTime.now());

  bool get _hasCurrentWeekReport {
    final weekStart = _currentWeekMonday.toIso8601String().substring(0, 10);
    return rows.any(
      (row) =>
          _v(row, 'requestType').toLowerCase() == 'weeklyreport' &&
          _v(row, 'weekStartDate').startsWith(weekStart),
    );
  }
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      rows = await repo.ptRequests();
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (!mounted) return;
    setState(() => loading = false);

    final reportId = widget.initialReportId;
    if (!_openedInitialReport && reportId != null && reportId.isNotEmpty) {
      _openedInitialReport = true;
      final matching = rows.where(
        (row) => _v(row, 'reportId') == reportId,
      );
      if (matching.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showResult(matching.first);
        });
      }
    }
  }

  Future<void> create() async {
    if (!_isSunday) {
      _notice(
        context,
        'Báo cáo tuần chỉ mở vào Chủ nhật, sau khi tuần đã kết thúc.',
      );
      return;
    }
    if (_hasCurrentWeekReport) {
      _notice(context, 'Bạn đã gửi báo cáo cho tuần này.');
      return;
    }

    try {
      final coaches = await repo.myCoaches();
      final hasConnected = coaches.any((c) => _v(c, 'connectionStatus').toLowerCase() == 'connected');
      if (!hasConnected) {
        if (mounted) _notice(context, 'Bạn chưa Đăng ký kết nối với PT');
        return;
      }
    } catch (e) {
      if (mounted) _notice(context, e);
      return;
    }

    final monday = _currentWeekMonday;

    final noteController = TextEditingController();
    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    int selectedDays = 3;
    String selectedFeeling = 'Khỏe 😊';
    String submittedNote = '';
    double? submittedWeight;
    double? submittedBodyFat;

    if (!mounted) {
      // Dispose controllers trước khi thoát để tránh leak khi widget
      // đã bị unmount giữa lúc.
      noteController.dispose();
      weightController.dispose();
      bodyFatController.dispose();
      return;
    }

    final bool? shouldSubmit;
    try {
      shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Báo cáo & Check-in Tuần'),
        content: StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vui lòng điền các chỉ số thực tế tuần qua:',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  
                  // Weight Field
                  const Text(
                    'Cân nặng hiện tại (kg) *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: 68.5',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Body Fat Field
                  const Text(
                    'Tỷ lệ mỡ (%) (không bắt buộc)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: bodyFatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: 15.2',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Training Days Field
                  const Text(
                    'Số buổi đã tập tuần này',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDays,
                    items: List.generate(8, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('$i buổi'),
                    )),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedDays = val);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feeling Field
                  const Text(
                    'Cảm nhận thể trạng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFeeling,
                    items: const [
                      DropdownMenuItem(value: 'Khỏe 😊', child: Text('Khỏe 😊')),
                      DropdownMenuItem(value: 'Bình thường 😐', child: Text('Bình thường 😐')),
                      DropdownMenuItem(value: 'Mệt mỏi 😴', child: Text('Mệt mỏi 😴')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedFeeling = val);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note Field
                  const Text(
                    'Lời nhắn / Ghi chú gửi PT (không bắt buộc)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: Tuần này em bận đi du lịch nên ăn uống hơi lệch target...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text.trim());
              final bodyFat = bodyFatController.text.trim().isEmpty
                  ? null
                  : double.tryParse(bodyFatController.text.trim());
              if (weight == null || weight < 20 || weight > 400) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Cân nặng phải nằm trong khoảng 20–400 kg'),
                  ),
                );
                return;
              }
              if (bodyFatController.text.trim().isNotEmpty &&
                  (bodyFat == null || bodyFat < 1 || bodyFat > 75)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Tỷ lệ mỡ phải nằm trong khoảng 1–75%'),
                  ),
                );
                return;
              }
              submittedNote = noteController.text.trim();
              submittedWeight = weight;
              submittedBodyFat = bodyFat;
              Navigator.pop(ctx, true);
            },
            child: const Text('Gửi báo cáo'),
          ),
        ],
      ),
    );
    } finally {
      // Luôn dispose controllers khi dialog đóng (thành công hoặc huỷ)
      // để tránh leak và lỗi "dependents.isEmpty is not true" khi widget
      // TextField bị dispose cùng widget cha nhưng controller chưa được
      // remove khỏi dependents.
      noteController.dispose();
      weightController.dispose();
      bodyFatController.dispose();
    }

    if (shouldSubmit != true) return;

    try {
      final r = await repo.createPtReport(
        monday.toIso8601String().substring(0, 10),
        7,
        studentNote: submittedNote.isEmpty ? null : submittedNote,
        checkInWeight: submittedWeight,
        checkInBodyFat: submittedBodyFat,
        trainingDaysCount: selectedDays,
        bodyFeeling: selectedFeeling,
      );
      if (mounted) _notice(context, 'Đã tạo link: ${_v(r, 'shareLink')}');
      await load();
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  Future<void> showResult(Map<String, dynamic> row) async {
    try {
      final result = await repo.ptResult(_v(row, 'reportId'));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final studentNote = _v(result, 'studentNote');
          final checkInWeight = _v(result, 'checkInWeight');
          final checkInBodyFat = _v(result, 'checkInBodyFat');
          final trainingDaysCount = _v(result, 'trainingDaysCount');
          final bodyFeeling = _v(result, 'bodyFeeling');

          return AlertDialog(
            title: Text('Kết quả tuần ${_v(result, 'weekStartDate')}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upper Part: Gymer check-in report
                  const Text(
                    'Báo cáo check-in từ Gymer:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cân nặng thực tế:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            Text(
                              checkInWeight.isNotEmpty ? '$checkInWeight kg' : '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tỷ lệ mỡ cơ thể:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            Text(
                              checkInBodyFat.isNotEmpty ? '$checkInBodyFat %' : '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số buổi đã tập:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            Text(
                              trainingDaysCount.isNotEmpty ? '$trainingDaysCount buổi' : '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cảm nhận thể trạng:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            Text(
                              bodyFeeling.isNotEmpty ? bodyFeeling : '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                        if (studentNote.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Ghi chú của bạn:', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              studentNote,
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lower Part: PT Evaluation
                  Text(
                    'Đánh giá & Nhận xét từ PT:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade800),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• PT nhận xét: ${_v(result, 'ptComment', 'Chưa có nhận xét')}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Calo đề xuất: ${_v(result, 'suggestedCalorieTarget', '-')} kcal',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Protein đề xuất: ${_v(result, 'suggestedProteinTarget', '-')} g',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Trạng thái: ${_v(result, 'status')}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Thay đổi thực đơn đề xuất:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if ((result['suggestedChanges'] ?? result['SuggestedChanges']) is List)
                    for (final raw in (result['suggestedChanges'] ?? result['SuggestedChanges']) as List)
                      if (raw is Map)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${raw['action'] ?? raw['Action']} • ${raw['mealType'] ?? raw['MealType']}',
                          ),
                          subtitle: Text(
                            '${raw['dayOfWeek'] ?? raw['DayOfWeek']}\n${raw['notes'] ?? raw['Notes'] ?? ''}',
                          ),
                        ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;
    switch (status.toLowerCase()) {
      case 'pending':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'Chờ duyệt';
        break;
      case 'reviewed':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Đã nhận xét';
        break;
      case 'applied':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Đã áp dụng';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Từ chối';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: _isSunday && !_hasCurrentWeekReport
                    ? create
                    : null,
                icon: Icon(
                  _hasCurrentWeekReport
                      ? Icons.check_circle_outline
                      : Icons.calendar_today,
                ),
                label: Text(
                  _hasCurrentWeekReport
                      ? 'Đã gửi báo cáo tuần này'
                      : _isSunday
                      ? 'Tạo báo cáo tuần này'
                      : 'Mở vào Chủ nhật',
                ),
              ),
              if (!_isSunday && !_hasCurrentWeekReport) ...[
                const SizedBox(height: 8),
                const Text(
                  'Bạn chỉ có thể tạo báo cáo vào Chủ nhật sau khi hoàn tất dữ liệu của cả tuần.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (rows.where((r) => _v(r, 'requestType').toLowerCase() == 'weeklyreport').isEmpty)
                const Center(child: Text('Chưa có yêu cầu review')),
              for (final r in rows.where((r) => _v(r, 'requestType').toLowerCase() == 'weeklyreport'))
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tuần ${_v(r, 'weekStartDate')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            _buildStatusBadge(_v(r, 'status')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_v(r, 'checkInWeight').isNotEmpty ||
                            _v(r, 'trainingDaysCount').isNotEmpty ||
                            _v(r, 'bodyFeeling').isNotEmpty ||
                            _v(r, 'studentNote').isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chỉ số check-in của bạn:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (_v(r, 'checkInWeight').isNotEmpty)
                                      Text('Cân nặng: ${_v(r, 'checkInWeight')} kg${_v(r, 'checkInBodyFat').isNotEmpty ? ' (Mỡ: ${_v(r, 'checkInBodyFat')}%)' : ''}', style: const TextStyle(fontSize: 12)),
                                    if (_v(r, 'trainingDaysCount').isNotEmpty)
                                      Text('Tập: ${_v(r, 'trainingDaysCount')} buổi', style: const TextStyle(fontSize: 12)),
                                    if (_v(r, 'bodyFeeling').isNotEmpty)
                                      Text('Thể trạng: ${_v(r, 'bodyFeeling')}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                if (_v(r, 'studentNote').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ghi chú: "${_v(r, 'studentNote')}"',
                                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_v(r, 'status').toLowerCase() == 'reviewed' || _v(r, 'status').toLowerCase() == 'applied') ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đánh giá & Mục tiêu từ PT:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Nhận xét: ${_v(r, 'ptComment', 'Chưa có nhận xét')}',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Calo đề xuất: ${_v(r, 'suggestedCalorieTarget', '-')} kcal',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Protein đề xuất: ${_v(r, 'suggestedProteinTarget', '-')} g',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else if (_v(r, 'status').toLowerCase() == 'pending') ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Đang chờ huấn luyện viên nhận xét và cập nhật mục tiêu mới...',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_v(r, 'status').toLowerCase() == 'reviewed')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  final localContext = context;
                                  try {
                                    await repo.ptAction(_v(r, 'reportId'), 'reject');
                                    await load();
                                  } catch (e) {
                                    if (localContext.mounted) _notice(localContext, e);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Từ chối'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () async {
                                  final localContext = context;
                                  try {
                                    await repo.ptAction(_v(r, 'reportId'), 'apply');
                                    await load();
                                  } catch (e) {
                                    if (localContext.mounted) _notice(localContext, e);
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Áp dụng mục tiêu mới'),
                              ),
                            ],
                          )
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => showResult(r),
                              child: const Text('Xem chi tiết thực đơn thay đổi'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
}

class _BudgetTab extends StatefulWidget {
  const _BudgetTab();
  @override
  State<_BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<_BudgetTab> {
  final repo = AdvancedRepository();
  final planRepo = MealPlanRepository();
  Map<String, dynamic>? data;
  bool loading = true;
  bool generating = false;
  final amount = TextEditingController(), minutes = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    // Dispose TextEditingController để tránh
    // "dependents.isEmpty is not true" khi TextField con vẫn còn dependent
    // vào controller khi widget unmount.
    amount.dispose();
    minutes.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      data = await repo.budget();
      amount.text = data == null ? '' : _v(data!, 'budgetVnd');
      minutes.text = data == null ? '' : _v(data!, 'timeLimitMin');
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final a = int.tryParse(amount.text), m = int.tryParse(minutes.text);
    if (a == null || m == null) {
      _notice(context, 'Nhập số hợp lệ');
      return;
    }
    try {
      data = await repo.saveBudget(
        id: data == null ? null : _v(data!, 'id'),
        amount: a,
        minutes: m,
      );
      if (mounted) {
        setState(() {});
        _notice(context, 'Đã lưu ngân sách');
      }
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  Future<void> generateLunchboxPlan() async {
    if (data == null) {
      _notice(context, 'Hãy lưu ngân sách trước khi tạo cơm hộp.');
      return;
    }
    setState(() => generating = true);
    try {
      final plan = await planRepo.generateBudgetLunchboxPlan();
      final grocery = await planRepo.getGroceryList(plan.id);
      if (!mounted) return;
      final items = (grocery['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                '${item['name'] ?? item['Name']}: ${item['quantity'] ?? item['Quantity']} ${item['unit'] ?? item['Unit']}',
          )
          .join('\n');
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(plan.title),
          content: SingleChildScrollView(
            child: Text(
              'Danh sách đi chợ\n\n${items.isEmpty ? 'Chưa có nguyên liệu từ recipe của kế hoạch.' : items}\n\nTổng giá ước tính: ${grocery['estimatedTotalVnd'] ?? grocery['EstimatedTotalVnd'] ?? 0}đ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator())
      : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách (VND)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thời gian nấu tối đa (phút)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: save,
              child: Text(data == null ? 'Tạo ngân sách' : 'Cập nhật'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: generating ? null : generateLunchboxPlan,
              icon: generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lunch_dining_outlined),
              label: Text(
                generating ? 'Đang tạo...' : 'Tạo kế hoạch cơm hộp Office',
              ),
            ),
            if (data != null)
              TextButton(
                onPressed: () async {
                  await repo.deleteBudget(_v(data!, 'id'));
                  data = null;
                  amount.clear();
                  minutes.clear();
                  if (mounted) setState(() {});
                },
                child: const Text(
                  'Xóa giới hạn',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
}

class _CoachTab extends StatefulWidget {
  const _CoachTab({this.gymerMode = false});

  final bool gymerMode;

  @override
  State<_CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<_CoachTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> connectedCoaches = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      connectedCoaches = await repo.myCoaches();
      rows = await repo.coaches();
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> showCoach(Map<String, dynamic> row) async {
    try {
      final detail = await repo.coach(_v(row, 'id'));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        showDragHandle: false,
        builder: (sheetContext) {
          final isConnected = connectedCoaches.any(
            (c) => _v(c, 'id') == _v(detail, 'id'),
          );
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar + name
                Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.sports_gymnastics_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _v(detail, 'fullName'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _v(detail, 'specialty'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  children: [
                    _DetailStat(
                      icon: Icons.star_rounded,
                      label: '${_v(detail, 'experienceYears')} năm',
                      sub: 'Kinh nghiệm',
                    ),
                    const SizedBox(width: 12),
                    _DetailStat(
                      icon: Icons.payments_outlined,
                      label: '${_v(detail, 'priceVnd')} đ',
                      sub: 'Học phí',
                    ),
                  ],
                ),
                if (_v(detail, 'bio').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    _v(detail, 'bio'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
                const SizedBox(height: 20),
                if (isConnected) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Cấp quyền xem',
                          icon: Icons.lock_open_rounded,
                          color: AppColors.primary,
                          onTap: () async {
                            await repo.access(_v(detail, 'id'), true);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Thu hồi quyền',
                          icon: Icons.lock_rounded,
                          color: Colors.red.shade400,
                          onTap: () async {
                            await repo.access(_v(detail, 'id'), false);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await repo.connect(_v(detail, 'id'));
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          load();
                        }
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Gửi yêu cầu kết nối'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (!widget.gymerMode)
                Row(
                  children: [
                    Expanded(
                      child: _OutlineChip(
                        label: 'Đăng ký Coach',
                        icon: Icons.verified_user_outlined,
                        onTap: () => Navigator.push(
                          c, MaterialPageRoute(builder: (_) => const CoachRegisterScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OutlineChip(
                        label: 'Học viên',
                        icon: Icons.group_outlined,
                        onTap: () => Navigator.push(
                          c, MaterialPageRoute(builder: (_) => const CoachClientsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              if (!widget.gymerMode) const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_gymnastics_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.gymerMode ? 'Huấn luyện viên phù hợp' : 'Danh bạ coach',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      if (widget.gymerMode)
                        Text(
                          'Chủ động cấp hoặc thu hồi quyền xem dữ liệu',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Connected section
              if (connectedCoaches.isNotEmpty) ...[
                _SectionLabel(label: 'Đang kết nối', icon: Icons.link_rounded, color: AppColors.primary),
                const SizedBox(height: 10),
                for (final r in connectedCoaches)
                  _CoachCard(
                    name: _v(r, 'fullName'),
                    specialty: _v(r, 'specialty'),
                    experienceYears: _v(r, 'experienceYears'),
                    priceVnd: _v(r, 'priceVnd'),
                    status: _v(r, 'connectionStatus'),
                    isConnected: true,
                    onTap: () => showCoach(r),
                    onAction: () async {
                      final isConn = _v(r, 'connectionStatus').toLowerCase() == 'connected';
                      final title = isConn ? 'Hủy kết nối' : 'Hủy yêu cầu';
                      final confirm = await showDialog<bool>(
                        context: c,
                        builder: (d) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(title),
                          content: Text(isConn
                              ? 'Bạn có chắc muốn hủy kết nối với huấn luyện viên này?'
                              : 'Bạn có chắc muốn rút lại yêu cầu?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Bỏ qua')),
                            TextButton(
                              onPressed: () => Navigator.pop(d, true),
                              child: Text(title, style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await repo.disconnect(_v(r, 'id'));
                          if (c.mounted) { _notice(c, isConn ? 'Đã hủy kết nối' : 'Đã hủy yêu cầu'); load(); }
                        } catch (e) { if (c.mounted) _notice(c, e); }
                      }
                    },
                    actionLabel: _v(r, 'connectionStatus').toLowerCase() == 'connected' ? 'Hủy kết nối' : 'Hủy yêu cầu',
                    actionColor: Colors.red,
                  ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Khám phá thêm', icon: Icons.explore_rounded, color: Colors.grey.shade600),
                const SizedBox(height: 10),
              ],

              // Available coaches
              if (rows.isEmpty && connectedCoaches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.sports_gymnastics_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Chưa có huấn luyện viên', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  ),
                )
              else
                for (final r in rows)
                  _CoachCard(
                    name: _v(r, 'fullName'),
                    specialty: _v(r, 'specialty'),
                    experienceYears: _v(r, 'experienceYears'),
                    priceVnd: _v(r, 'priceVnd'),
                    status: '',
                    isConnected: false,
                    onTap: () => showCoach(r),
                    onAction: () async {
                      try {
                        await repo.connect(_v(r, 'id'));
                        if (c.mounted) { _notice(c, 'Đã gửi yêu cầu kết nối'); load(); }
                      } catch (e) { if (c.mounted) _notice(c, e); }
                    },
                    actionLabel: 'Kết nối',
                    actionColor: AppColors.primary,
                  ),
            ],
          ),
        );
}

class _IngredientTab extends StatefulWidget {
  const _IngredientTab();
  @override
  State<_IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<_IngredientTab> {
  final repo = AdvancedRepository(),
      search = TextEditingController(),
      category = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool safe = false, loading = false;

  @override
  void dispose() {
    // Dispose TextEditingController để tránh
    // "dependents.isEmpty is not true" khi TextField con vẫn còn dependent
    // vào controller khi widget unmount.
    search.dispose();
    category.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await repo.ingredients(
        search.text,
        safe,
        category: category.text.trim(),
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: search,
          onSubmitted: (_) => load(),
          decoration: InputDecoration(
            labelText: 'Tìm nguyên liệu',
            suffixIcon: IconButton(
              onPressed: load,
              icon: const Icon(Icons.search),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: category,
          onSubmitted: (_) => load(),
          decoration: InputDecoration(
            labelText: 'Lọc theo danh mục',
            suffixIcon: IconButton(
              onPressed: load,
              icon: const Icon(Icons.filter_alt_outlined),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      SwitchListTile(
        value: safe,
        onChanged: (v) {
          safe = v;
          load();
        },
        title: const Text('Chỉ hiện nguyên liệu an toàn dị ứng'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            onPressed: () async {
              final changed = await Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const IngredientEditScreen()),
              );
              if (changed == true) load();
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm (Admin)'),
          ),
        ),
      ),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  for (final r in rows)
                    ListTile(
                      onTap: () async {
                        await Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => IngredientDetailScreen(
                              ingredient: r,
                              safe: safe,
                            ),
                          ),
                        );
                        await load();
                      },
                      leading: Icon(
                        _v(r, 'isSafeForUser', 'true') == 'true'
                            ? Icons.verified
                            : Icons.warning,
                        color: _v(r, 'isSafeForUser', 'true') == 'true'
                            ? AppColors.primary
                            : Colors.orange,
                      ),
                      title: Text(_v(r, 'nameVi')),
                      subtitle: Text(
                        '${_v(r, 'category')} • ${_v(r, 'caloriesKcal')} kcal',
                      ),
                    ),
                ],
              ),
      ),
    ],
  );
}

class _UserTab extends StatefulWidget {
  const _UserTab();
  @override
  State<_UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<_UserTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      rows = await repo.users();
      error = null;
    } catch (e) {
      error = 'Chỉ tài khoản Admin được truy cập.';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator())
      : error != null
      ? Center(child: Text(error!))
      : RefreshIndicator(
          onRefresh: load,
          child: ListView(
            children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(userId: _v(r, 'id')),
                      ),
                    ),
                    title: Text(_v(r, 'fullName')),
                    subtitle: Text('${_v(r, 'email')} • ${_v(r, 'role')}'),
                    leading: Icon(
                      _v(r, 'isActive') == 'true'
                          ? Icons.person
                          : Icons.person_off,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) async {
                        try {
                          if (a.startsWith('role:')) {
                            await repo.userAction(
                              _v(r, 'id'),
                              'assign-role',
                              a.substring(5),
                            );
                          } else {
                            await repo.userAction(_v(r, 'id'), a);
                          }
                          await load();
                        } catch (e) {
                          if (c.mounted) _notice(c, e);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'toggle-status',
                          child: Text('Bật/tắt trạng thái'),
                        ),
                        PopupMenuItem(value: 'lock', child: Text('Khóa')),
                        PopupMenuItem(value: 'unlock', child: Text('Mở khóa')),
                        PopupMenuItem(
                          value: 'role:User',
                          child: Text('Gán User'),
                        ),
                        PopupMenuItem(
                          value: 'role:Coach',
                          child: Text('Gán Coach'),
                        ),
                        PopupMenuItem(
                          value: 'role:Admin',
                          child: Text('Gán Admin'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
}

// ─── Helper widgets for _CoachTab ─────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.priceVnd,
    required this.status,
    required this.isConnected,
    required this.onTap,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
  });

  final String name, specialty, experienceYears, priceVnd, status;
  final bool isConnected;
  final VoidCallback onTap, onAction;
  final String actionLabel;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    final isConn = status.toLowerCase() == 'connected';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConnected
                        ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.65)]
                        : [const Color(0xFF6EE7B7), const Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.sports_gymnastics_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isConn
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isConn ? 'Đã kết nối' : 'Chờ duyệt',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isConn
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action button
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: actionColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.label,
    required this.sub,
  });

  final IconData icon;
  final String label, sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                Text(sub, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

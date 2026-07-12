import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/advanced_repository.dart';
import 'advanced_detail_screens.dart';

class AdvancedFeaturesScreen extends StatelessWidget {
  const AdvancedFeaturesScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Dịch vụ & quản lý'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'PT Review'),
            Tab(text: 'Ngân sách'),
            Tab(text: 'Coach'),
            Tab(text: 'Nguyên liệu'),
            Tab(text: 'Người dùng'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _PtTab(),
          _BudgetTab(),
          _CoachTab(),
          _IngredientTab(),
          _UserTab(),
        ],
      ),
    ),
  );
}

String _v(Map<String, dynamic> m, String key, [String fallback = '']) =>
    (m[key] ?? m[key[0].toUpperCase() + key.substring(1)] ?? fallback)
        .toString();
void _notice(BuildContext c, Object value) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(value.toString().replaceFirst('Exception: ', ''))),
    );

class _PtTab extends StatefulWidget {
  const _PtTab();
  @override
  State<_PtTab> createState() => _PtTabState();
}

class _PtTabState extends State<_PtTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
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
    if (mounted) setState(() => loading = false);
  }

  Future<void> create() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    try {
      final r = await repo.createPtReport(
        monday.toIso8601String().substring(0, 10),
        7,
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
        builder: (dialogContext) => AlertDialog(
          title: Text('Kết quả tuần ${_v(result, 'weekStartDate')}'),
          content: SingleChildScrollView(
            child: Text(
              'PT: ${_v(result, 'ptComment', 'Chưa có nhận xét')}\nCalo đề xuất: ${_v(result, 'suggestedCalorieTarget', '-')}\nProtein đề xuất: ${_v(result, 'suggestedProteinTarget', '-')}\nTrạng thái: ${_v(result, 'status')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
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
                onPressed: create,
                icon: const Icon(Icons.add_link),
                label: const Text('Tạo báo cáo tuần này'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SharedPtReviewScreen(),
                  ),
                ),
                icon: const Icon(Icons.rate_review),
                label: const Text('Mở báo cáo bằng mã PT'),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Center(child: Text('Chưa có yêu cầu review')),
              for (final r in rows)
                Card(
                  child: ListTile(
                    onTap: () => showResult(r),
                    title: Text('Tuần ${_v(r, 'weekStartDate')}'),
                    subtitle: Text('Trạng thái: ${_v(r, 'status')}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) async {
                        try {
                          await repo.ptAction(_v(r, 'reportId'), a);
                          await load();
                        } catch (e) {
                          if (context.mounted) _notice(context, e);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'apply', child: Text('Áp dụng')),
                        PopupMenuItem(value: 'reject', child: Text('Từ chối')),
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
  Map<String, dynamic>? data;
  bool loading = true;
  final amount = TextEditingController(), minutes = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
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
  const _CoachTab();
  @override
  State<_CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<_CoachTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
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
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _v(detail, 'fullName'),
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              Text(
                '${_v(detail, 'specialty')} • ${_v(detail, 'experienceYears')} năm',
              ),
              const SizedBox(height: 8),
              Text(_v(detail, 'bio')),
              const SizedBox(height: 8),
              Text('Phí: ${_v(detail, 'priceVnd')} VND'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await repo.access(_v(detail, 'id'), true);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      child: const Text('Cấp quyền'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await repo.access(_v(detail, 'id'), false);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      child: const Text('Thu hồi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) => const CoachRegisterScreen(),
                        ),
                      ),
                      child: const Text('Đăng ký Coach'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) => const CoachClientsScreen(),
                        ),
                      ),
                      child: const Text('Học viên của tôi'),
                    ),
                  ),
                ],
              ),
              const Text(
                'Danh bạ coach',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    onTap: () => showCoach(r),
                    leading: const CircleAvatar(
                      child: Icon(Icons.fitness_center),
                    ),
                    title: Text(_v(r, 'fullName')),
                    subtitle: Text(
                      '${_v(r, 'specialty')} • ${_v(r, 'experienceYears')} năm\n${_v(r, 'priceVnd')} VND',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () async {
                        try {
                          await repo.connect(_v(r, 'id'));
                          if (c.mounted) _notice(c, 'Đã gửi yêu cầu kết nối');
                        } catch (e) {
                          if (c.mounted) _notice(c, e);
                        }
                      },
                      child: const Text('Kết nối'),
                    ),
                  ),
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
  final repo = AdvancedRepository(), search = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool safe = false, loading = false;
  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await repo.ingredients(search.text, safe);
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

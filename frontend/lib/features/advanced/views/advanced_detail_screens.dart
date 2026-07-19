import 'dart:convert';
import 'package:flutter/material.dart';
import '../repositories/advanced_repository.dart';

String valueOf(Map<String, dynamic> data, String key, [String fallback = '']) =>
    (data[key] ?? data[key[0].toUpperCase() + key.substring(1)] ?? fallback)
        .toString();

void showError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );

class SharedPtReviewScreen extends StatefulWidget {
  const SharedPtReviewScreen({super.key, this.initialToken});
  final String? initialToken;
  @override
  State<SharedPtReviewScreen> createState() => _SharedPtReviewScreenState();
}

class _SharedPtReviewScreenState extends State<SharedPtReviewScreen> {
  final repo = AdvancedRepository();
  late final TextEditingController token = TextEditingController(
    text: widget.initialToken,
  );
  final comment = TextEditingController(),
      calories = TextEditingController(),
      protein = TextEditingController();
  Map<String, dynamic>? report;
  final List<Map<String, String>> changes = [];
  bool loading = false;

  Future<void> addChange() async {
    final day = TextEditingController(),
        meal = TextEditingController(),
        notes = TextEditingController(),
        oldFood = TextEditingController(),
        newFood = TextEditingController(),
        newRecipe = TextEditingController();
    String action = 'Replace';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đề xuất thay đổi món'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: day,
                  decoration: const InputDecoration(
                    labelText: 'Ngày trong tuần, ví dụ Monday',
                  ),
                ),
                TextField(
                  controller: meal,
                  decoration: const InputDecoration(
                    labelText: 'Bữa ăn, ví dụ Breakfast',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  items: const [
                    DropdownMenuItem(value: 'Replace', child: Text('Thay món')),
                    DropdownMenuItem(value: 'Add', child: Text('Thêm món')),
                    DropdownMenuItem(value: 'Remove', child: Text('Bỏ món')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => action = value ?? action),
                ),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả món thay đổi / ghi chú',
                  ),
                ),
                TextField(
                  controller: oldFood,
                  decoration: const InputDecoration(
                    labelText: 'Food ID cũ (không bắt buộc)',
                  ),
                ),
                TextField(
                  controller: newFood,
                  decoration: const InputDecoration(
                    labelText: 'Food ID mới (không bắt buộc)',
                  ),
                ),
                TextField(
                  controller: newRecipe,
                  decoration: const InputDecoration(
                    labelText: 'Recipe ID mới (không bắt buộc)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true &&
        day.text.trim().isNotEmpty &&
        meal.text.trim().isNotEmpty) {
      setState(
        () => changes.add({
          'dayOfWeek': day.text.trim(),
          'mealType': meal.text.trim(),
          'action': action,
          'notes': notes.text.trim(),
          if (oldFood.text.trim().isNotEmpty) 'oldFoodId': oldFood.text.trim(),
          if (newFood.text.trim().isNotEmpty) 'newFoodId': newFood.text.trim(),
          if (newRecipe.text.trim().isNotEmpty)
            'newRecipeId': newRecipe.text.trim(),
        }),
      );
    }
  }

  Future<void> load() async {
    if (token.text.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      report = await repo.sharedPtReport(token.text.trim());
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> submit() async {
    if (comment.text.trim().isEmpty) {
      showError(context, 'Vui lòng nhập nhận xét');
      return;
    }
    try {
      await repo.submitPtReview(token.text.trim(), {
        'comment': comment.text.trim(),
        'suggestedCalorieTarget': int.tryParse(calories.text),
        'suggestedProteinTarget': int.tryParse(protein.text),
        'suggestedChanges': changes,
      });
      if (mounted) {
        showError(context, 'Đã gửi đánh giá');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PT đánh giá báo cáo')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: token,
          decoration: InputDecoration(
            labelText: 'Mã chia sẻ',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: load,
              icon: const Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (report != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOf(report!, 'studentName'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Tuần: ${valueOf(report!, 'weekStartDate')}'),
                  Text('Trạng thái: ${valueOf(report!, 'status')}'),
                  Text('Hết hạn: ${valueOf(report!, 'expiresAt')}'),
                ],
              ),
            ),
          ),
          TextField(
            controller: comment,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nhận xét',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calo đề xuất',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: addChange,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Thêm thay đổi thực đơn'),
          ),
          for (var i = 0; i < changes.length; i++)
            ListTile(
              title: Text(
                '${changes[i]['action']} • ${changes[i]['mealType']}',
              ),
              subtitle: Text(
                '${changes[i]['dayOfWeek']}\n${changes[i]['notes']}',
              ),
              trailing: IconButton(
                onPressed: () => setState(() => changes.removeAt(i)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          FilledButton.icon(
            onPressed: submit,
            icon: const Icon(Icons.send),
            label: const Text('Gửi đánh giá'),
          ),
        ],
      ],
    ),
  );
}

class CoachRegisterScreen extends StatefulWidget {
  const CoachRegisterScreen({super.key});
  @override
  State<CoachRegisterScreen> createState() => _CoachRegisterScreenState();
}

class _CoachRegisterScreenState extends State<CoachRegisterScreen> {
  final repo = AdvancedRepository(),
      specialty = TextEditingController(),
      bio = TextEditingController(),
      years = TextEditingController(),
      price = TextEditingController(),
      certificate = TextEditingController();
  Future<void> save() async {
    final y = int.tryParse(years.text), p = int.tryParse(price.text);
    if (specialty.text.trim().isEmpty ||
        bio.text.trim().isEmpty ||
        y == null ||
        p == null) {
      showError(context, 'Vui lòng nhập đủ thông tin');
      return;
    }
    try {
      await repo.registerCoach({
        'specialty': specialty.text.trim(),
        'bio': bio.text.trim(),
        'experienceYears': y,
        'priceVnd': p,
        'certificateUrl': certificate.text.trim().isEmpty
            ? null
            : certificate.text.trim(),
      });
      if (mounted) {
        showError(context, 'Đăng ký coach thành công');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Đăng ký Coach')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in [
          (specialty, 'Chuyên môn'),
          (bio, 'Giới thiệu'),
          (years, 'Số năm kinh nghiệm'),
          (price, 'Phí dịch vụ VND'),
          (certificate, 'URL chứng chỉ'),
        ]) ...[
          TextField(
            controller: item.$1,
            keyboardType: item.$1 == years || item.$1 == price
                ? TextInputType.number
                : TextInputType.text,
            maxLines: item.$1 == bio ? 3 : 1,
            decoration: InputDecoration(
              labelText: item.$2,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(onPressed: save, child: const Text('Đăng ký')),
      ],
    ),
  );
}

class CoachClientsScreen extends StatefulWidget {
  const CoachClientsScreen({super.key});
  @override
  State<CoachClientsScreen> createState() => _CoachClientsScreenState();
}

class MyCoachesScreen extends StatefulWidget {
  const MyCoachesScreen({super.key});
  @override
  State<MyCoachesScreen> createState() => _MyCoachesScreenState();
}

class _MyCoachesScreenState extends State<MyCoachesScreen> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> coaches = [], feedback = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        repo.myCoaches(),
        repo.myCoachFeedback(),
      ]);
      coaches = results[0];
      feedback = results[1];
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Coach của tôi')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  'Kết nối',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (coaches.isEmpty) const Text('Chưa có kết nối coach.'),
                for (final coach in coaches)
                  Card(
                    child: ListTile(
                      title: Text(valueOf(coach, 'fullName')),
                      subtitle: Text(
                        '${valueOf(coach, 'specialty')} • ${valueOf(coach, 'connectionStatus')}\nQuyền dữ liệu: ${valueOf(coach, 'isAccessGranted')}',
                      ),
                      isThreeLine: true,
                      trailing:
                          valueOf(coach, 'connectionStatus').toLowerCase() ==
                              'connected'
                          ? Switch(
                              value:
                                  valueOf(coach, 'isAccessGranted') == 'true',
                              onChanged: (grant) async {
                                await repo.access(valueOf(coach, 'id'), grant);
                                await load();
                              },
                            )
                          : null,
                    ),
                  ),
                const Divider(),
                const Text(
                  'Phản hồi đã nhận',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (feedback.isEmpty) const Text('Chưa có phản hồi.'),
                for (final item in feedback)
                  ListTile(
                    title: Text(valueOf(item, 'content')),
                    subtitle: Text(
                      '${valueOf(item, 'coachName')} • ${valueOf(item, 'createdAt')}',
                    ),
                  ),
              ],
            ),
          ),
  );
}

class _CoachClientsScreenState extends State<CoachClientsScreen> with SingleTickerProviderStateMixin {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;
  late TabController _tabController;

  // Mock Notifications for PT/Coach
  final List<Map<String, dynamic>> mockNotifications = [
    {
      'id': 'noti_1',
      'title': 'Yêu cầu đánh giá mới',
      'body': 'Học viên Nguyễn Văn A vừa gửi yêu cầu đánh giá tuần mới.',
      'time': '10 phút trước',
      'clientName': 'Nguyễn Văn A',
      'isRead': false,
    },
    {
      'id': 'noti_2',
      'title': 'Đăng ký liên kết',
      'body': 'Học viên Trần Thị B muốn liên kết với bạn làm PT.',
      'time': '1 giờ trước',
      'clientName': 'Trần Thị B',
      'isRead': false,
    },
    {
      'id': 'noti_3',
      'title': 'Cập nhật cân nặng',
      'body': 'Học viên Lê Hoàng C vừa cập nhật cân nặng mới (72 kg).',
      'time': '2 giờ trước',
      'clientName': 'Lê Hoàng C',
      'isRead': true,
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      rows = await repo.clients();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  void _handleNotificationTap(Map<String, dynamic> noti) {
    final clientName = valueOf(noti, 'clientName');
    final match = rows.firstWhere(
      (r) => valueOf(r, 'fullName').toLowerCase() == clientName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    setState(() {
      noti['isRead'] = true;
    });

    if (match.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoachClientDetailScreen(client: match),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy học viên $clientName hoặc chưa được chấp nhận kết nối.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Không gian của PT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Học viên'),
            Tab(icon: Icon(Icons.notifications), text: 'Thông báo'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Thống kê'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Clients List & Quick stats
                    RefreshIndicator(
                      onRefresh: load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              _buildStatCard('Tổng học viên', '${rows.where((r) => valueOf(r, 'connectionStatus').toLowerCase() == 'connected').length}', Colors.blue),
                              const SizedBox(width: 12),
                              _buildStatCard('Chờ duyệt', '${rows.where((r) => valueOf(r, 'connectionStatus').toLowerCase() == 'pending').length}', Colors.orange),
                              const SizedBox(width: 12),
                              _buildStatCard('Tuân thủ calo', '85%', Colors.green),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Danh sách học viên',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          if (rows.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('Chưa có học viên nào liên kết.')),
                            )
                          else
                            ...rows.map((row) => _buildClientListItem(row, primaryColor)),
                        ],
                      ),
                    ),

                    // Tab 2: Notifications Deep-linking
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Thông báo học tập & tập luyện',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...mockNotifications.map((noti) => Card(
                              elevation: valueOf(noti, 'isRead') == 'true' ? 0.5 : 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              color: valueOf(noti, 'isRead') == 'true' ? Colors.white : primaryColor.withValues(alpha: 0.05),
                              child: ListTile(
                                leading: Icon(
                                  noti['title'] == 'Đăng ký liên kết'
                                      ? Icons.person_add
                                      : Icons.assignment_turned_in,
                                  color: primaryColor,
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      valueOf(noti, 'title'),
                                      style: TextStyle(
                                        fontWeight: valueOf(noti, 'isRead') == 'true' ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      valueOf(noti, 'time'),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(valueOf(noti, 'body')),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                                onTap: () => _handleNotificationTap(noti),
                              ),
                            )),
                      ],
                    ),

                    // Tab 3: Analytics / Health adherence columns
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Biểu đồ mức độ tuân thủ thực đơn tuần này',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildChartBar('T.Hai', 90, primaryColor),
                              _buildChartBar('T.Ba', 75, primaryColor),
                              _buildChartBar('T.Tư', 85, primaryColor),
                              _buildChartBar('T.Năm', 95, primaryColor),
                              _buildChartBar('T.Sáu', 60, Colors.redAccent),
                              _buildChartBar('T.Bảy', 80, primaryColor),
                              _buildChartBar('C.Nhật', 88, primaryColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nhận xét chung của hệ thống',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tuần này tỉ lệ tuân thủ calo của học viên đạt trung bình 82.5%, tăng 4% so với tuần trước. Thứ Sáu có xu hướng tuân thủ thấp nhất do các hoạt động cuối tuần. Hãy khuyến khích học viên lưu ý thực đơn Thứ Sáu.',
                                  style: TextStyle(color: Colors.grey.shade700, height: 1.4, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String day, int percentage, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$percentage%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          height: percentage * 1.3,
          width: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildClientListItem(Map<String, dynamic> row, Color primaryColor) {
    final status = valueOf(row, 'connectionStatus').toLowerCase();
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          child: Text(
            valueOf(row, 'fullName').isNotEmpty ? valueOf(row, 'fullName')[0].toUpperCase() : 'U',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          valueOf(row, 'fullName'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isPending ? 'Đang chờ bạn duyệt kết nối' : 'Đang kết nối • ${valueOf(row, 'email')}',
            style: TextStyle(
              fontSize: 12,
              color: isPending ? Colors.orange.shade700 : Colors.grey.shade600,
              fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () async {
                      await repo.approveClient(valueOf(row, 'clientId'), true);
                      await load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () async {
                      await repo.approveClient(valueOf(row, 'clientId'), false);
                      await load();
                    },
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachClientDetailScreen(client: row),
                  ),
                ),
              ),
      ),
    );
  }
}

class CoachClientDetailScreen extends StatefulWidget {
  const CoachClientDetailScreen({super.key, required this.client});
  final Map<String, dynamic> client;
  @override
  State<CoachClientDetailScreen> createState() =>
      _CoachClientDetailScreenState();
}

class _CoachClientDetailScreenState extends State<CoachClientDetailScreen> {
  final repo = AdvancedRepository();
  final feedbackText = TextEditingController();
  final cal = TextEditingController();
  final protein = TextEditingController();
  final carbs = TextEditingController();
  final fat = TextEditingController();
  
  // Weekly Review feedback fields
  final reviewComment = TextEditingController();
  final reviewCalorie = TextEditingController();
  final reviewProtein = TextEditingController();

  // Route Approval feedback fields
  final routeComment = TextEditingController();
  final routeCalorie = TextEditingController();
  final routeProtein = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _suggestionPage = 0;

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> nutrition = [];
  List<Map<String, dynamic>> feedbacks = [], weights = [];
  
  // New variables to hold client meal plan, AI suggestions, and review requests
  Map<String, dynamic>? mealPlan;
  List<Map<String, dynamic>> aiSuggestions = [];
  List<Map<String, dynamic>> reviewRequests = [];

  bool loading = true;
  String get id => valueOf(widget.client, 'clientId');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final results = await Future.wait([
        repo.clientProfile(id),
        repo.clientNutrition(id),
        repo.clientWeight(id),
        repo.feedback(id),
        repo.clientMealPlan(id, dateStr),
        repo.clientSuggestions(id),
        repo.clientReviewRequests(id),
      ]);
      profile = results[0] as Map<String, dynamic>;
      nutrition = results[1] as List<Map<String, dynamic>>;
      weights = results[2] as List<Map<String, dynamic>>;
      feedbacks = results[3] as List<Map<String, dynamic>>;
      mealPlan = results[4] as Map<String, dynamic>?;
      aiSuggestions = results[5] as List<Map<String, dynamic>>;
      reviewRequests = results[6] as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> sendFeedback() async {
    if (feedbackText.text.trim().isEmpty) return;
    try {
      await repo.addFeedback(id, 'General', feedbackText.text.trim());
      feedbackText.clear();
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi tin nhắn trao đổi.')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> targets() async {
    final values = [
      cal,
      protein,
      carbs,
      fat,
    ].map((e) => int.tryParse(e.text)).toList();
    if (values.any((e) => e == null)) {
      showError(context, 'Nhập đủ 4 mục tiêu');
      return;
    }
    try {
      await repo.adjustTargets(id, {
        'targetCalories': values[0],
        'targetProteinG': values[1],
        'targetCarbsG': values[2],
        'targetFatG': values[3],
      });
      await load();
      if (mounted) showError(context, 'Đã cập nhật mục tiêu sức khỏe.');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> submitWeeklyReview(String token) async {
    final commentVal = reviewComment.text.trim();
    final calVal = int.tryParse(reviewCalorie.text);
    final proVal = int.tryParse(reviewProtein.text);

    if (commentVal.isEmpty) {
      showError(context, 'Vui lòng nhập nhận xét/đánh giá');
      return;
    }

    try {
      setState(() => loading = true);
      await repo.submitPtReview(token, {
        'comment': commentVal,
        'suggestedCalorieTarget': calVal,
        'suggestedProteinTarget': proVal,
        'suggestedChanges': <dynamic>[],
      });
      
      reviewComment.clear();
      reviewCalorie.clear();
      reviewProtein.clear();
      
      await load();
      if (mounted) {
        Navigator.pop(context); // Close review dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá tuần thành công!')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteMealPlanItem(Map<String, dynamic> itemToDelete) async {
    if (mealPlan == null) return;
    try {
      setState(() => loading = true);
      final items = <Map<String, dynamic>>[];
      if (mealPlan!['items'] is List) {
        for (final item in mealPlan!['items'] as List) {
          final itemFoodId = valueOf(item, 'foodId');
          final itemRecipeId = valueOf(item, 'recipeId');
          final targetFoodId = valueOf(itemToDelete, 'foodId');
          final targetRecipeId = valueOf(itemToDelete, 'recipeId');
          final itemMealType = valueOf(item, 'mealType');
          final targetMealType = valueOf(itemToDelete, 'mealType');
          
          if (itemMealType.toLowerCase() == targetMealType.toLowerCase() &&
              (itemFoodId.isNotEmpty && itemFoodId == targetFoodId ||
               itemRecipeId.isNotEmpty && itemRecipeId == targetRecipeId)) {
            continue;
          }
          
          items.add({
            'mealType': valueOf(item, 'mealType'),
            'foodId': itemFoodId.isEmpty ? null : itemFoodId,
            'recipeId': itemRecipeId.isEmpty ? null : itemRecipeId,
            'targetCalories': double.tryParse(valueOf(item, 'targetCalories'))?.round() ?? 200,
            'plannedDate': valueOf(item, 'plannedDate').isEmpty ? null : valueOf(item, 'plannedDate'),
            'scheduledTime': valueOf(item, 'scheduledTime').isEmpty ? null : valueOf(item, 'scheduledTime'),
            'isCompleted': valueOf(item, 'isCompleted').toString().toLowerCase() == 'true',
          });
        }
      }

      await repo.adjustMealPlan(id, valueOf(mealPlan!, 'id'), {
        'title': valueOf(mealPlan!, 'title'),
        'planType': 'CoachAdjusted',
        'targetCalories': int.tryParse(valueOf(mealPlan!, 'targetCalories')),
        'isActive': true,
        'items': items,
      });

      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa món ăn khỏi thực đơn của học viên!')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submitRouteApproval(String token) async {
    final commentVal = routeComment.text.trim();
    final calVal = int.tryParse(routeCalorie.text);
    final proVal = int.tryParse(routeProtein.text);

    if (commentVal.isEmpty) {
      showError(context, 'Vui lòng nhập nhận xét/ý kiến cho lộ trình');
      return;
    }

    try {
      setState(() => loading = true);
      await repo.submitPtReview(token, {
        'comment': commentVal,
        'suggestedCalorieTarget': calVal,
        'suggestedProteinTarget': proVal,
        'suggestedChanges': <dynamic>[],
      });
      
      routeComment.clear();
      routeCalorie.clear();
      routeProtein.clear();
      
      await load();
      if (mounted) {
        Navigator.pop(context); // Close review dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt lộ trình của học viên thành công!')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showRouteApprovalDialog(Map<String, dynamic> req) {
    routeComment.clear();
    routeCalorie.text = '${valueOf(profile ?? {}, 'trainingDayTargetCalories', '2000')}';
    routeProtein.text = '${valueOf(profile ?? {}, 'minProteinG', '120')}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt Lộ trình Dinh dưỡng'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '1. Lộ trình từ Gymer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Chế độ mục tiêu: ${valueOf(profile ?? {}, 'goal', 'Chưa đặt')}'),
                      const SizedBox(height: 4),
                      Text('• Calo ngày tập: ${valueOf(profile ?? {}, 'trainingDayTargetCalories', '-')} kcal'),
                      const SizedBox(height: 4),
                      Text('• Calo ngày nghỉ: ${valueOf(profile ?? {}, 'restDayTargetCalories', '-')} kcal'),
                      const SizedBox(height: 4),
                      Text('• Protein tối thiểu: ${valueOf(profile ?? {}, 'minProteinG', '-')} g'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Ý kiến & Điều chỉnh của PT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: routeComment,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét/Ý kiến đóng góp',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: routeCalorie,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calo đề xuất',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: routeProtein,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein đề xuất (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => submitRouteApproval(valueOf(req, 'reviewToken')),
            child: const Text('Duyệt lộ trình'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> req) {
    reviewComment.clear();
    reviewCalorie.text = '${valueOf(profile ?? {}, 'trainingDayTargetCalories', '2000')}';
    reviewProtein.text = '${valueOf(profile ?? {}, 'minProteinG', '120')}';
    
    final reportDataJson = valueOf(req, 'reportDataJson');
    Map<String, dynamic> reportData = {};
    try {
      if (reportDataJson.isNotEmpty) {
        reportData = jsonDecode(reportDataJson) as Map<String, dynamic>;
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không gian Đánh giá Báo cáo Tuần'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '1. Báo cáo từ Gymer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ngày bắt đầu tuần:', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
                          Text(valueOf(req, 'weekStartDate'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trạng thái yêu cầu:', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
                          Text(valueOf(req, 'status'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cân nặng TB (tự động):', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
                          Text('${valueOf(reportData, 'averageWeight', '-')} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Calo TB (tự động):', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
                          Text('${valueOf(reportData, 'averageCalories', '-')} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                      if (valueOf(reportData, 'checkInWeight').isNotEmpty ||
                          valueOf(reportData, 'trainingDaysCount').isNotEmpty ||
                          valueOf(reportData, 'bodyFeeling').isNotEmpty ||
                          valueOf(reportData, 'studentNote').isNotEmpty) ...[
                        const Divider(height: 16),
                        const Text(
                          'Chỉ số Gymer tự check-in:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cân nặng thực tế:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
                            Text('${valueOf(reportData, 'checkInWeight', '-')} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tỷ lệ mỡ cơ thể:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
                            Text(valueOf(reportData, 'checkInBodyFat').isNotEmpty ? '${valueOf(reportData, 'checkInBodyFat')}%' : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số buổi đã tập:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
                            Text(valueOf(reportData, 'trainingDaysCount').isNotEmpty ? '${valueOf(reportData, 'trainingDaysCount')} buổi' : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cảm nhận thể trạng:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
                            Text(valueOf(reportData, 'bodyFeeling', '-'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                        if (valueOf(reportData, 'studentNote').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Ghi chú/Lời nhắn:', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              valueOf(reportData, 'studentNote'),
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Đề xuất & Nhận xét của PT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewComment,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét/Lời khuyên dinh dưỡng',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: reviewCalorie,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calo đề xuất',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: reviewProtein,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein đề xuất (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => submitWeeklyReview(valueOf(req, 'reviewToken')),
            child: const Text('Gửi đánh giá'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanHeaderSection(Color primaryColor) {
    final dateStr = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: primaryColor),
                const SizedBox(width: 10),
                Text(
                  'Ngày xem: $dateStr',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    loading = true;
                  });
                  await load();
                }
              },
              icon: const Icon(Icons.edit_calendar, size: 16),
              label: const Text('Chọn ngày'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(valueOf(widget.client, 'fullName')),
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Hồ sơ cá nhân'),
              Tab(icon: Icon(Icons.restaurant), text: 'Lộ trình & Gợi ý'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Hồ sơ cá nhân
                  RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text('Hồ sơ sức khỏe của học viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                const Divider(),
                                Text(
                                  '• Chiều cao: ${valueOf(profile ?? {}, 'heightCm', '-')} cm  '
                                  '• Cân nặng: ${valueOf(profile ?? {}, 'weightKg', '-')} kg\n'
                                  '• BMI: ${valueOf(profile ?? {}, 'bmi', '-')}  '
                                  '• Mục tiêu: ${valueOf(profile ?? {}, 'goal', '-')}\n'
                                  '• Calo mục tiêu: ${valueOf(profile ?? {}, 'trainingDayTargetCalories', '-')} kcal\n'
                                  '• Dị ứng: ${valueOf(profile ?? {}, 'allergies', 'Không có')}',
                                  style: TextStyle(color: Colors.grey.shade800, height: 1.5, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildReviewRequestsSection(primaryColor),
                        const SizedBox(height: 16),
                        _buildTrendsSection(),
                        const SizedBox(height: 16),
                        _buildTargetsAdjustmentSection(primaryColor),
                        const SizedBox(height: 16),
                        _buildChatBoardSection(primaryColor),
                      ],
                    ),
                  ),
                  
                  // Tab 2: Lộ trình & Gợi ý
                  RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMealPlanHeaderSection(primaryColor),
                        const SizedBox(height: 16),
                        _buildDayReviewCard(primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDayReviewCard(Color primaryColor) {
    final dateStr = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
    final itemsList = mealPlan != null && mealPlan!['items'] is List
        ? mealPlan!['items'] as List
        : <dynamic>[];
    final totalCal = itemsList.fold<double>(
      0,
      (sum, x) => sum + (double.tryParse(valueOf(x, 'targetCalories')) ?? 0),
    );
    final totalItems = itemsList.length;

    final pendingReqs = reviewRequests
        .where((r) => valueOf(r, 'status').toLowerCase() == 'pending' && 
                      (valueOf(r, 'requestType').isEmpty || valueOf(r, 'requestType').toLowerCase() == 'routeapproval'))
        .toList();
    final hasPendingReview = pendingReqs.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDayReviewSheet(primaryColor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.rate_review_rounded, color: primaryColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá ngày $dateStr',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalItems == 0
                          ? 'Chưa có món ăn nào trong ngày này'
                          : '$totalItems món · ${totalCal.round()} kcal tổng cộng',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (hasPendingReview) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          '⚡ Có yêu cầu duyệt đang chờ',
                          style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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

  void _showDayReviewSheet(Color primaryColor) {
    final dateLabel = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayReviewSheet(
        primaryColor: primaryColor,
        dateLabel: dateLabel,
        selectedDate: _selectedDate,
        mealPlan: mealPlan,
        aiSuggestions: aiSuggestions,
        reviewRequests: reviewRequests,
        onDeleteItem: _deleteMealPlanItem,
        onAssignItem: (item, mealType) async {
          if (mealPlan == null) {
            showError(context, 'Học viên chưa có Meal Plan nào để gán.');
            return;
          }
          setState(() => loading = true);
          try {
            final items = <Map<String, dynamic>>[];
            if (mealPlan!['items'] is List) {
              for (final existing in mealPlan!['items'] as List) {
                items.add({
                  'mealType': valueOf(existing, 'mealType'),
                  'foodId': valueOf(existing, 'foodId').isEmpty ? null : valueOf(existing, 'foodId'),
                  'recipeId': valueOf(existing, 'recipeId').isEmpty ? null : valueOf(existing, 'recipeId'),
                  'targetCalories': double.tryParse(valueOf(existing, 'targetCalories'))?.round() ?? 200,
                  'plannedDate': valueOf(existing, 'plannedDate').isEmpty ? null : valueOf(existing, 'plannedDate'),
                  'scheduledTime': valueOf(existing, 'scheduledTime').isEmpty ? null : valueOf(existing, 'scheduledTime'),
                  'isCompleted': valueOf(existing, 'isCompleted').toString().toLowerCase() == 'true',
                });
              }
            }
            final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
            items.add({
              'mealType': mealType,
              'foodId': valueOf(item, 'type').toLowerCase().contains('recipe') ? null : valueOf(item, 'id'),
              'recipeId': valueOf(item, 'type').toLowerCase().contains('recipe') ? valueOf(item, 'id') : null,
              'targetCalories': double.tryParse(valueOf(item, 'caloriesKcal'))?.round() ?? 200,
              'plannedDate': dateStr,
              'isCompleted': false,
            });
            await repo.adjustMealPlan(id, valueOf(mealPlan!, 'id'), {
              'title': valueOf(mealPlan!, 'title'),
              'planType': 'CoachAdjusted',
              'targetCalories': int.tryParse(valueOf(mealPlan!, 'targetCalories')),
              'isActive': true,
              'items': items,
            });
            final nav = Navigator.of(ctx);
            await load();
            if (mounted) {
              nav.pop();
              _showDayReviewSheet(primaryColor);
            }
          } catch (e) {
            if (mounted) showError(context, e);
          } finally {
            if (mounted) setState(() => loading = false);
          }
        },
        onApprove: (req) async {
          Navigator.pop(ctx);
          _showRouteApprovalDialog(req);
        },
      ),
    );
  }

  // _buildMealPlanSection and _buildAiSuggestionsSection moved into _DayReviewSheet
  // ignore: unused_element
  Widget _buildMealPlanSection(Color primaryColor) {
    final itemsList = mealPlan != null && mealPlan!['items'] is List
        ? mealPlan!['items'] as List
        : <dynamic>[];

    final meals = {
      'breakfast': 'Bữa sáng',
      'lunch': 'Bữa trưa',
      'dinner': 'Bữa tối',
      'snack': 'Bữa phụ / Ăn thêm'
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green),
                SizedBox(width: 8),
                Text('Lộ trình ăn uống của học viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            if (mealPlan == null || itemsList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Học viên chưa lên thực đơn cho ngày này.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ...meals.entries.map((m) {
                final mealType = m.key;
                final mealTitle = m.value;
                final mealItems = itemsList.where((x) => valueOf(x, 'mealType').toLowerCase() == mealType).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      if (mealItems.isEmpty)
                        const Text('  • Chưa có món ăn', style: TextStyle(color: Colors.grey, fontSize: 12))
                      else
                        ...mealItems.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${valueOf(item, 'foodName').isNotEmpty ? valueOf(item, 'foodName') : valueOf(item, 'recipeName')}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '${valueOf(item, 'targetCalories')} kcal',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () => _deleteMealPlanItem(item),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAiSuggestionsSection(Color primaryColor) {
    final addedIds = mealPlan != null && mealPlan!['items'] is List
        ? (mealPlan!['items'] as List)
            .map((x) => (valueOf(x, 'foodId').isEmpty ? valueOf(x, 'recipeId') : valueOf(x, 'foodId')).trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet()
        : <String>{};

    final remainingSuggestions = aiSuggestions
        .where((x) => !addedIds.contains(valueOf(x, 'id').trim().toLowerCase()))
        .toList();

    const itemsPerPage = 5;
    final totalSuggestions = remainingSuggestions.length;
    final totalPages = (totalSuggestions / itemsPerPage).ceil();

    if (_suggestionPage >= totalPages && totalPages > 0) {
      _suggestionPage = totalPages - 1;
    }
    if (_suggestionPage < 0) {
      _suggestionPage = 0;
    }

    final pagedSuggestions = remainingSuggestions
        .skip(_suggestionPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Món gợi ý thông minh từ AI cho học viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            if (pagedSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Không có món gợi ý phù hợp.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              Column(
                children: [
                  for (final item in pagedSuggestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            valueOf(item, 'type').toLowerCase().contains('recipe')
                                ? Icons.menu_book
                                : Icons.restaurant,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    valueOf(item, 'name'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${double.tryParse(valueOf(item, 'caloriesKcal'))?.toStringAsFixed(0) ?? '0'} kcal • P ${double.tryParse(valueOf(item, 'proteinG'))?.toStringAsFixed(0) ?? '0'}g',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            PopupMenuButton<String>(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Gợi ý gán',
                                  style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onSelected: (mealType) async {
                                if (mealPlan == null) {
                                  showError(context, 'Học viên chưa có Meal Plan nào khởi tạo để gán.');
                                  return;
                                }
                                try {
                                  setState(() => loading = true);
                                  final items = <Map<String, dynamic>>[];
                                  
                                  // Copy existing items
                                  if (mealPlan!['items'] is List) {
                                    for (final existing in mealPlan!['items'] as List) {
                                      items.add({
                                        'mealType': valueOf(existing, 'mealType'),
                                        'foodId': valueOf(existing, 'foodId').isEmpty ? null : valueOf(existing, 'foodId'),
                                        'recipeId': valueOf(existing, 'recipeId').isEmpty ? null : valueOf(existing, 'recipeId'),
                                        'targetCalories': double.tryParse(valueOf(existing, 'targetCalories'))?.round() ?? 200,
                                        'plannedDate': valueOf(existing, 'plannedDate').isEmpty ? null : valueOf(existing, 'plannedDate'),
                                        'scheduledTime': valueOf(existing, 'scheduledTime').isEmpty ? null : valueOf(existing, 'scheduledTime'),
                                        'isCompleted': valueOf(existing, 'isCompleted').toString().toLowerCase() == 'true',
                                      });
                                    }
                                  }

                                  // Add the new suggested item
                                  final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
                                  items.add({
                                    'mealType': mealType,
                                    'foodId': valueOf(item, 'type').toLowerCase().contains('recipe') ? null : valueOf(item, 'id'),
                                    'recipeId': valueOf(item, 'type').toLowerCase().contains('recipe') ? valueOf(item, 'id') : null,
                                    'targetCalories': double.tryParse(valueOf(item, 'caloriesKcal'))?.round() ?? 200,
                                    'plannedDate': dateStr,
                                    'isCompleted': false
                                  });

                                  await repo.adjustMealPlan(id, valueOf(mealPlan!, 'id'), {
                                    'title': valueOf(mealPlan!, 'title'),
                                    'planType': 'CoachAdjusted',
                                    'targetCalories': int.tryParse(valueOf(mealPlan!, 'targetCalories')),
                                    'isActive': true,
                                    'items': items,
                                  });
                                  await load();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã gán và đề xuất món ăn thành công!')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) showError(context, e);
                                } finally {
                                  if (mounted) setState(() => loading = false);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                                const PopupMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                                const PopupMenuItem(value: 'dinner', child: Text('Bữa tối')),
                                const PopupMenuItem(value: 'snack', child: Text('Bữa phụ')),
                              ],
                            ),
                          ],
                        ),
                      )
                  ],
                ),
            if (totalPages > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: _suggestionPage > 0
                        ? () => setState(() => _suggestionPage--)
                        : null,
                  ),
                  Text(
                    'Trang ${_suggestionPage + 1} / $totalPages',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _suggestionPage < totalPages - 1
                        ? () => setState(() => _suggestionPage++)
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRequestsSection(Color primaryColor) {
    final reports = reviewRequests
        .where((r) => valueOf(r, 'requestType').isEmpty || valueOf(r, 'requestType').toLowerCase() == 'weeklyreport')
        .toList();

    if (reports.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.assignment, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text(
                'Chưa có yêu cầu đánh giá nào',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final pendingReqs = reports.where((r) => valueOf(r, 'status').toLowerCase() == 'pending').toList();
    final reqToDisplay = pendingReqs.isNotEmpty ? pendingReqs.first : reports.first;
    
    final status = valueOf(reqToDisplay, 'status');
    final isPending = status.toLowerCase() == 'pending';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isPending ? () => _showReviewDialog(reqToDisplay) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.assignment, color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? '⚡ Yêu cầu đánh giá tuần mới' : 'Yêu cầu đánh giá tuần',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tuần ngày: ${valueOf(reqToDisplay, 'weekStartDate')} • Trạng thái: $status',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (isPending)
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orangeAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text('Dinh dưỡng & Cân nặng gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            if (nutrition.isEmpty && weights.isEmpty)
              const Text('Chưa có dữ liệu xu hướng sức khỏe.', style: TextStyle(color: Colors.grey, fontSize: 13))
            else ...[
              if (nutrition.isNotEmpty) ...[
                const Text('Dinh dưỡng 7 ngày qua:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                for (final day in nutrition.take(3))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(valueOf(day, 'date'), style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                      'Hấp thu calo: ${valueOf(day, 'actualCalories')}/${valueOf(day, 'targetCalories')} kcal  '
                      '• Protein: ${valueOf(day, 'actualProtein')}/${valueOf(day, 'targetProtein')} g',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
              if (weights.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Cân nặng gần đây:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                for (final point in weights.take(2))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.monitor_weight, size: 16),
                    title: Text('${valueOf(point, 'weightKg')} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text('Đo ngày: ${valueOf(point, 'recordedAt')} • Mỡ cơ thể: ${valueOf(point, 'bodyFatPercent')}%', style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsAdjustmentSection(Color primaryColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_road, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Điều chỉnh chỉ số Calo/Macros trực tiếp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Calo', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: protein,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Protein', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: carbs,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Carbs', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: fat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fat', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: targets,
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Lưu thay đổi mục tiêu'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 38)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBoardSection(Color primaryColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Khung trao đổi nhanh với học viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            if (feedbacks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Chưa có tin nhắn nào trao đổi.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView(
                  shrinkWrap: true,
                  children: feedbacks.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(valueOf(f, 'content'), style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    valueOf(f, 'coachName').isNotEmpty ? valueOf(f, 'coachName') : 'PT/Coach',
                                    style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    valueOf(f, 'createdAt'),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: feedbackText,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn/lời khuyên...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: primaryColor),
                  onPressed: sendFeedback,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IngredientDetailScreen extends StatefulWidget {
  const IngredientDetailScreen({
    super.key,
    required this.ingredient,
    required this.safe,
  });
  final Map<String, dynamic> ingredient;
  final bool safe;
  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  final repo = AdvancedRepository();
  Map<String, dynamic>? data;
  List<Map<String, dynamic>> recipes = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      data = await repo.ingredient(
        valueOf(widget.ingredient, 'id'),
        widget.safe,
      );
      recipes = await repo.ingredientRecipes(valueOf(widget.ingredient, 'id'));
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(valueOf(widget.ingredient, 'nameVi')),
      actions: [
        IconButton(
          onPressed: () async {
            final changed = await Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => IngredientEditScreen(ingredient: data),
              ),
            );
            if (changed == true) load();
          },
          icon: const Icon(Icons.edit),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                valueOf(data!, 'nameVi'),
                style: Theme.of(c).textTheme.headlineSmall,
              ),
              Text(
                '${valueOf(data!, 'nameEn')} • ${valueOf(data!, 'category')}',
              ),
              const SizedBox(height: 12),
              Text(
                'Calo: ${valueOf(data!, 'caloriesKcal')} kcal\nProtein: ${valueOf(data!, 'proteinG')} g\nCarbs: ${valueOf(data!, 'carbsG')} g\nFat: ${valueOf(data!, 'fatG')} g\nGiá ước tính: ${valueOf(data!, 'estimatedPriceVnd')} VND\nMức dị ứng: ${valueOf(data!, 'allergyRiskLevel')}',
              ),
              const Divider(),
              const Text(
                'Công thức sử dụng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (recipes.isEmpty) const Text('Chưa có công thức'),
              for (final r in recipes)
                ListTile(
                  title: Text(valueOf(r, 'nameVi', valueOf(r, 'name'))),
                  subtitle: Text(valueOf(r, 'description')),
                ),
            ],
          ),
  );
}

class IngredientEditScreen extends StatefulWidget {
  const IngredientEditScreen({super.key, this.ingredient});
  final Map<String, dynamic>? ingredient;
  @override
  State<IngredientEditScreen> createState() => _IngredientEditScreenState();
}

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId});
  final String userId;
  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final repo = AdvancedRepository();
  Map<String, dynamic>? user;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      user = await repo.user(widget.userId);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết người dùng')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : user == null
        ? const Center(child: Text('Không tìm thấy người dùng'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 36,
                child: Text(valueOf(user!, 'fullName', '?').characters.first),
              ),
              const SizedBox(height: 16),
              for (final field in [
                ('Họ tên', 'fullName'),
                ('Email', 'email'),
                ('Vai trò', 'role'),
                ('Đang hoạt động', 'isActive'),
                ('Đã xác nhận email', 'emailConfirmed'),
                ('Ngày tạo', 'createdAt'),
                ('Đăng nhập gần nhất', 'lastSignInAt'),
              ])
                ListTile(
                  title: Text(field.$1),
                  subtitle: Text(valueOf(user!, field.$2, '-')),
                ),
            ],
          ),
  );
}

class _IngredientEditScreenState extends State<IngredientEditScreen> {
  final repo = AdvancedRepository();
  late final fields = <String, TextEditingController>{
    for (final k in [
      'nameVi',
      'nameEn',
      'category',
      'caloriesKcal',
      'proteinG',
      'carbsG',
      'fatG',
      'estimatedPriceVnd',
      'unitDefault',
      'imageUrl',
    ])
      k: TextEditingController(
        text: widget.ingredient == null ? '' : valueOf(widget.ingredient!, k),
      ),
  };
  Future<void> save() async {
    if (fields['nameVi']!.text.trim().isEmpty) {
      showError(context, 'Tên tiếng Việt là bắt buộc');
      return;
    }
    num? number(String k) => num.tryParse(fields[k]!.text);
    try {
      await repo.saveIngredient(
        widget.ingredient == null ? null : valueOf(widget.ingredient!, 'id'),
        {
          'nameVi': fields['nameVi']!.text.trim(),
          'nameEn': fields['nameEn']!.text.trim(),
          'category': fields['category']!.text.trim(),
          'caloriesKcal': number('caloriesKcal'),
          'proteinG': number('proteinG'),
          'carbsG': number('carbsG'),
          'fatG': number('fatG'),
          'estimatedPriceVnd': int.tryParse(fields['estimatedPriceVnd']!.text),
          'unitDefault': fields['unitDefault']!.text.trim(),
          'imageUrl': fields['imageUrl']!.text.trim(),
          'isActive': true,
        },
      );
      if (mounted) {
        showError(context, 'Đã lưu nguyên liệu');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.ingredient == null ? 'Thêm nguyên liệu' : 'Sửa nguyên liệu',
      ),
      actions: [
        if (widget.ingredient != null)
          IconButton(
            onPressed: () async {
              try {
                await repo.deleteIngredient(valueOf(widget.ingredient!, 'id'));
                if (c.mounted) Navigator.pop(c, true);
              } catch (e) {
                if (c.mounted) showError(c, e);
              }
            },
            icon: const Icon(Icons.delete),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final e in fields.entries) ...[
          TextField(
            controller: e.value,
            keyboardType:
                [
                  'caloriesKcal',
                  'proteinG',
                  'carbsG',
                  'fatG',
                  'estimatedPriceVnd',
                ].contains(e.key)
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: e.key,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(onPressed: save, child: const Text('Lưu')),
      ],
    ),
  );
}
// ─────────────────────────────────────────
// _DayReviewSheet – bottom sheet opened when PT taps the review card
// ─────────────────────────────────────────
class _DayReviewSheet extends StatefulWidget {
  final Color primaryColor;
  final String dateLabel;
  final DateTime selectedDate;
  final Map<String, dynamic>? mealPlan;
  final List<Map<String, dynamic>> aiSuggestions;
  final List<Map<String, dynamic>> reviewRequests;
  final Future<void> Function(Map<String, dynamic> item) onDeleteItem;
  final Future<void> Function(Map<String, dynamic> item, String mealType) onAssignItem;
  final Future<void> Function(Map<String, dynamic> req) onApprove;

  const _DayReviewSheet({
    required this.primaryColor,
    required this.dateLabel,
    required this.selectedDate,
    required this.mealPlan,
    required this.aiSuggestions,
    required this.reviewRequests,
    required this.onDeleteItem,
    required this.onAssignItem,
    required this.onApprove,
  });

  @override
  State<_DayReviewSheet> createState() => _DayReviewSheetState();
}

class _DayReviewSheetState extends State<_DayReviewSheet> {
  int _page = 0;
  bool _working = false;
  static const _perPage = 5;

  String _v(dynamic data, String key) {
    if (data is! Map<String, dynamic>) return '';
    return valueOf(data, key);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;
    final itemsList = widget.mealPlan != null && widget.mealPlan!['items'] is List
        ? widget.mealPlan!['items'] as List
        : <dynamic>[];

    // Build AI suggestions, removing already-added ones
    final addedIds = itemsList
        .map((x) => (
              _v(x, 'foodId').isEmpty ? _v(x, 'recipeId') : _v(x, 'foodId')
            ).trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();
    final remaining = widget.aiSuggestions
        .where((x) => !addedIds.contains(_v(x, 'id').trim().toLowerCase()))
        .toList();
    final totalPages = (remaining.length / _perPage).ceil().clamp(1, 9999);
    if (_page >= totalPages) _page = totalPages - 1;
    if (_page < 0) _page = 0;
    final paged = remaining.skip(_page * _perPage).take(_perPage).toList();

    final pendingReqs = widget.reviewRequests
        .where((r) => _v(r, 'status').toLowerCase() == 'pending' && 
                      (_v(r, 'requestType').isEmpty || _v(r, 'requestType').toLowerCase() == 'routeapproval'))
        .toList();

    final meals = {
      'breakfast': 'Bữa sáng',
      'lunch': 'Bữa trưa',
      'dinner': 'Bữa tối',
      'snack': 'Bữa phụ / Ăn thêm',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.rate_review_rounded, color: primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đánh giá ngày ${widget.dateLabel}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Meal Plan Section ──
                  _sectionHeader(Icons.restaurant_menu, 'Lộ trình ăn uống', primary),
                  const SizedBox(height: 8),
                  if (itemsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Học viên chưa có món ăn nào trong ngày này.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...meals.entries.map((m) {
                      final mealItems = itemsList
                          .where((x) => _v(x as Map<String, dynamic>, 'mealType').toLowerCase() == m.key)
                          .toList();
                      if (mealItems.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              m.value,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary),
                            ),
                          ),
                          ...mealItems.map((item) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: primary.withValues(alpha: 0.12),
                                    child: Icon(Icons.restaurant, color: primary, size: 16),
                                  ),
                                  title: Text(
                                    _v(item as Map<String, dynamic>, 'foodName').isNotEmpty
                                        ? _v(item, 'foodName')
                                        : _v(item, 'recipeName'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${_v(item, 'targetCalories')} kcal · ${_v(item, 'plannedDate')}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: _working
                                        ? null
                                        : () async {
                                            setState(() => _working = true);
                                            await widget.onDeleteItem(item);
                                            if (mounted) setState(() => _working = false);
                                          },
                                  ),
                                ),
                              )),
                        ],
                      );
                    }),
                  const SizedBox(height: 20),

                  // ── AI Suggestions Section ──
                  _sectionHeader(Icons.psychology, 'Gợi ý từ AI', Colors.deepPurple),
                  const SizedBox(height: 8),
                  if (paged.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Không còn món gợi ý phù hợp.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...paged.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _v(item, 'type').toLowerCase().contains('recipe')
                                      ? Icons.menu_book
                                      : Icons.restaurant,
                                  size: 18,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _v(item, 'name'),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${double.tryParse(_v(item, 'caloriesKcal'))?.toStringAsFixed(0) ?? '0'} kcal · P${double.tryParse(_v(item, 'proteinG'))?.toStringAsFixed(0) ?? '0'}g',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  enabled: !_working,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Gán vào',
                                      style: TextStyle(fontSize: 11, color: widget.primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  onSelected: (mealType) async {
                                    setState(() => _working = true);
                                    await widget.onAssignItem(item, mealType);
                                    if (mounted) setState(() => _working = false);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                                    const PopupMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                                    const PopupMenuItem(value: 'dinner', child: Text('Bữa tối')),
                                    const PopupMenuItem(value: 'snack', child: Text('Bữa phụ')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                  // Pagination
                  if (totalPages > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: _page > 0 ? () => setState(() => _page--) : null,
                        ),
                        Text('Trang ${_page + 1} / $totalPages', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Bottom action bar ──
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: pendingReqs.isEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Không có yêu cầu duyệt'),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _working
                              ? null
                              : () => widget.onApprove(pendingReqs.first),
                          icon: const Icon(Icons.check_circle),
                          label: Text('Duyệt lộ trình (${pendingReqs.length} yêu cầu)'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
        ],
      );
}

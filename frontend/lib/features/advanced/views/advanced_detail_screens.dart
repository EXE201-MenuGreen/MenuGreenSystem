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

class _CoachClientsScreenState extends State<CoachClientsScreen> {
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
      rows = await repo.clients();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Học viên của tôi')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              children: [
                for (final row in rows)
                  Card(
                    child: ListTile(
                      title: Text(valueOf(row, 'fullName')),
                      subtitle: Text(
                        '${valueOf(row, 'connectionStatus')} • ${valueOf(row, 'email')}',
                      ),
                      trailing: Wrap(
                        children: [
                          if (valueOf(row, 'connectionStatus').toLowerCase() ==
                              'pending')
                            PopupMenuButton<bool>(
                              onSelected: (approved) async {
                                await repo.approveClient(
                                  valueOf(row, 'clientId'),
                                  approved,
                                );
                                await load();
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: true,
                                  child: Text('Chấp nhận'),
                                ),
                                PopupMenuItem(
                                  value: false,
                                  child: Text('Từ chối'),
                                ),
                              ],
                            ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CoachClientDetailScreen(client: row),
                              ),
                            ),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class CoachClientDetailScreen extends StatefulWidget {
  const CoachClientDetailScreen({super.key, required this.client});
  final Map<String, dynamic> client;
  @override
  State<CoachClientDetailScreen> createState() =>
      _CoachClientDetailScreenState();
}

class _CoachClientDetailScreenState extends State<CoachClientDetailScreen> {
  final repo = AdvancedRepository(),
      feedbackText = TextEditingController(),
      cal = TextEditingController(),
      protein = TextEditingController(),
      carbs = TextEditingController(),
      fat = TextEditingController(),
      planId = TextEditingController(),
      planTitle = TextEditingController(),
      planCalories = TextEditingController();
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> nutrition = [];
  List<Map<String, dynamic>> feedbacks = [], weights = [];
  bool loading = true;
  String get id => valueOf(widget.client, 'clientId');
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        repo.clientProfile(id),
        repo.clientNutrition(id),
        repo.clientWeight(id),
        repo.feedback(id),
      ]);
      profile = results[0] as Map<String, dynamic>;
      nutrition = results[1] as List<Map<String, dynamic>>;
      weights = results[2] as List<Map<String, dynamic>>;
      feedbacks = results[3] as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> sendFeedback() async {
    if (feedbackText.text.trim().isEmpty) return;
    await repo.addFeedback(id, 'General', feedbackText.text.trim());
    feedbackText.clear();
    await load();
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
      if (mounted) showError(context, 'Đã cập nhật mục tiêu');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> updateMealPlan() async {
    if (planId.text.trim().isEmpty || planTitle.text.trim().isEmpty) {
      showError(context, 'Nhập ID và tên kế hoạch');
      return;
    }
    try {
      await repo.adjustMealPlan(id, planId.text.trim(), {
        'title': planTitle.text.trim(),
        'planType': 'CoachAdjusted',
        'targetCalories': int.tryParse(planCalories.text),
        'isActive': true,
        'items': <dynamic>[],
      });
      if (mounted) showError(context, 'Đã cập nhật kế hoạch ăn');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(valueOf(widget.client, 'fullName'))),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Hồ sơ\nChiều cao: ${valueOf(profile ?? {}, 'heightCm', '-')} cm • Cân nặng: ${valueOf(profile ?? {}, 'weightKg', '-')} kg\nMục tiêu: ${valueOf(profile ?? {}, 'goal', '-')} • BMI: ${valueOf(profile ?? {}, 'bmi', '-')}\nDị ứng: ${valueOf(profile ?? {}, 'allergies', 'Không có')}',
                  ),
                ),
              ),
              const Text(
                'Dinh dưỡng 7 ngày',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (nutrition.isEmpty) const Text('Chưa có dữ liệu dinh dưỡng.'),
              for (final day in nutrition)
                ListTile(
                  dense: true,
                  title: Text(valueOf(day, 'date')),
                  subtitle: Text(
                    'Calo ${valueOf(day, 'actualCalories')}/${valueOf(day, 'targetCalories')} • Protein ${valueOf(day, 'actualProtein')}/${valueOf(day, 'targetProtein')} g',
                  ),
                ),
              const Text(
                'Xu hướng cân nặng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (weights.isEmpty) const Text('Chưa có bản ghi cân nặng.'),
              for (final point in weights)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${valueOf(point, 'weightKg', '-')} kg'),
                  subtitle: Text(
                    '${valueOf(point, 'recordedAt')} • Body fat ${valueOf(point, 'bodyFatPercent', '-')}%',
                  ),
                ),
              const Divider(),
              const Text(
                'Điều chỉnh mục tiêu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  for (final item in [
                    (cal, 'Calo'),
                    (protein, 'Protein'),
                    (carbs, 'Carbs'),
                    (fat, 'Fat'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: TextField(
                          controller: item.$1,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: item.$2),
                        ),
                      ),
                    ),
                ],
              ),
              FilledButton(
                onPressed: targets,
                child: const Text('Lưu mục tiêu'),
              ),
              const Divider(),
              const Text(
                'Điều chỉnh kế hoạch ăn',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: planId,
                decoration: const InputDecoration(labelText: 'Meal plan ID'),
              ),
              TextField(
                controller: planTitle,
                decoration: const InputDecoration(labelText: 'Tên kế hoạch'),
              ),
              TextField(
                controller: planCalories,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calo mục tiêu'),
              ),
              FilledButton(
                onPressed: updateMealPlan,
                child: const Text('Lưu kế hoạch'),
              ),
              const Divider(),
              TextField(
                controller: feedbackText,
                decoration: const InputDecoration(
                  labelText: 'Phản hồi cho học viên',
                  border: OutlineInputBorder(),
                ),
              ),
              FilledButton(
                onPressed: sendFeedback,
                child: const Text('Gửi phản hồi'),
              ),
              for (final f in feedbacks)
                ListTile(
                  title: Text(valueOf(f, 'content')),
                  subtitle: Text(
                    '${valueOf(f, 'coachName')} • ${valueOf(f, 'createdAt')}',
                  ),
                ),
            ],
          ),
  );
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

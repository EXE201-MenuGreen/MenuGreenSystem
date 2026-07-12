import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/reminder_models.dart';
import '../repositories/reminder_repository.dart';

class AdaptiveRemindersScreen extends StatefulWidget {
  const AdaptiveRemindersScreen({super.key});

  @override
  State<AdaptiveRemindersScreen> createState() => _AdaptiveRemindersScreenState();
}

class _AdaptiveRemindersScreenState extends State<AdaptiveRemindersScreen> {
  final _repository = ReminderRepository();
  ReminderProfile? _profile;
  List<ScheduledReminder> _reminders = const [];
  bool _loading = true;
  bool _savingProfile = false;
  bool _recalculating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Future.wait([_repository.getProfile(), _repository.getScheduled()]);
      if (!mounted) return;
      setState(() {
        _profile = data[0] as ReminderProfile;
        _reminders = data[1] as List<ScheduledReminder>;
      });
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProfileTime(String field) async {
    final profile = _profile;
    if (profile == null) return;
    final current = switch (field) {
      'breakfast' => profile.optimalBreakfastTime,
      'lunch' => profile.optimalLunchTime,
      _ => profile.optimalDinnerTime,
    };
    final selected = await showTimePicker(context: context, initialTime: _timeOfDay(current));
    if (selected == null || !mounted) return;
    final value = _formatTime(selected);
    setState(() {
      _profile = switch (field) {
        'breakfast' => profile.copyWith(optimalBreakfastTime: value),
        'lunch' => profile.copyWith(optimalLunchTime: value),
        _ => profile.copyWith(optimalDinnerTime: value),
      };
    });
  }

  Future<void> _saveProfile() async {
    final profile = _profile;
    if (profile == null || _savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      final saved = await _repository.updateProfile(profile);
      if (mounted) setState(() => _profile = saved);
      _message('Đã lưu giờ ăn ưu tiên.');
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _recalculate() async {
    if (_recalculating) return;
    setState(() => _recalculating = true);
    try {
      final profile = await _repository.recalculateProfile();
      if (mounted) setState(() => _profile = profile);
      _message('Đã cập nhật giờ ăn từ lịch sử nhật ký.');
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _recalculating = false);
    }
  }

  Future<void> _openEditor([ScheduledReminder? reminder]) async {
    final saved = await showModalBottomSheet<ScheduledReminder>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReminderEditor(reminder: reminder, repository: _repository),
    );
    if (saved == null || !mounted) return;
    await _load();
  }

  Future<void> _toggle(ScheduledReminder reminder, bool enabled) async {
    try {
      await _repository.update(reminder.id, isEnabled: enabled);
      if (mounted) {
        setState(() => _reminders = [
              for (final item in _reminders)
                if (item.id == reminder.id)
                  ScheduledReminder(
                    id: item.id,
                    title: item.title,
                    body: item.body,
                    isEnabled: enabled,
                    type: item.type,
                    scheduledAt: item.scheduledAt,
                  )
                else
                  item,
            ]);
      }
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    }
  }

  Future<void> _snooze(ScheduledReminder reminder, int minutes) async {
    try {
      await _repository.snooze(reminder.id, minutes);
      if (mounted) _message('Đã nhắc lại sau $minutes phút.');
      await _load();
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    }
  }

  Future<void> _delete(ScheduledReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhắc nhở?'),
        content: Text('Nhắc nhở "${reminder.title}" sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(reminder.id);
      if (mounted) setState(() => _reminders = _reminders.where((item) => item.id != reminder.id).toList());
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.replaceFirst('Exception: ', '')), backgroundColor: error ? Colors.red : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc nhở thông minh')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tạo nhắc nhở',
        onPressed: _loading ? null : () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Giờ ăn ưu tiên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Dùng để gợi ý thời điểm nhắc bữa ăn phù hợp với bạn.'),
                  const SizedBox(height: 12),
                  _ProfileTimeTile(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Bữa sáng',
                    time: profile!.optimalBreakfastTime,
                    onTap: () => _pickProfileTime('breakfast'),
                  ),
                  _ProfileTimeTile(
                    icon: Icons.light_mode_outlined,
                    title: 'Bữa trưa',
                    time: profile.optimalLunchTime,
                    onTap: () => _pickProfileTime('lunch'),
                  ),
                  _ProfileTimeTile(
                    icon: Icons.nights_stay_outlined,
                    title: 'Bữa tối',
                    time: profile.optimalDinnerTime,
                    onTap: () => _pickProfileTime('dinner'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _recalculating ? null : _recalculate,
                          icon: _recalculating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Tự tính từ nhật ký'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _savingProfile ? null : _saveProfile,
                          child: Text(_savingProfile ? 'Đang lưu...' : 'Lưu giờ ăn'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: Text('Lịch nhắc tùy chỉnh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      Text('${_reminders.length} lịch', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_reminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text('Chưa có nhắc nhở nào được lên lịch.')),
                    )
                  else
                    ..._reminders.map(
                      (reminder) => _ReminderTile(
                        reminder: reminder,
                        onTap: () => _openEditor(reminder),
                        onToggle: (enabled) => _toggle(reminder, enabled),
                        onSnooze: (minutes) => _snooze(reminder, minutes),
                        onDelete: () => _delete(reminder),
                      ),
                    ),
                  const SizedBox(height: 88),
                ],
              ),
      ),
    );
  }
}

class _ProfileTimeTile extends StatelessWidget {
  const _ProfileTimeTile({required this.icon, required this.title, required this.time, required this.onTap});

  final IconData icon;
  final String title;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          trailing: TextButton.icon(onPressed: onTap, icon: const Icon(Icons.schedule), label: Text(time)),
        ),
      );
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onTap,
    required this.onToggle,
    required this.onSnooze,
    required this.onDelete,
  });

  final ScheduledReminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onSnooze;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          title: Text(reminder.title),
          subtitle: Text('${_dateTimeLabel(reminder.scheduledAt)}${reminder.body.isEmpty ? '' : '\n${reminder.body}'}'),
          isThreeLine: reminder.body.isNotEmpty,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: reminder.isEnabled, onChanged: onToggle),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'snooze15') onSnooze(15);
                  if (value == 'snooze30') onSnooze(30);
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'snooze15', child: Text('Nhắc lại sau 15 phút')),
                  PopupMenuItem(value: 'snooze30', child: Text('Nhắc lại sau 30 phút')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ReminderEditor extends StatefulWidget {
  const _ReminderEditor({required this.repository, this.reminder});

  final ReminderRepository repository;
  final ScheduledReminder? reminder;

  @override
  State<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<_ReminderEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late DateTime _scheduledAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _title = TextEditingController(text: reminder?.title ?? 'Nhắc giờ ăn');
    _body = TextEditingController(text: reminder?.body ?? 'Đến giờ ghi nhật ký bữa ăn.');
    _scheduledAt = reminder?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(DateTime.now()) ? DateTime.now() : _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, _scheduledAt.hour, _scheduledAt.minute));
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledAt));
    if (time != null && mounted) {
      setState(() => _scheduledAt = DateTime(_scheduledAt.year, _scheduledAt.month, _scheduledAt.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty || !_scheduledAt.isAfter(DateTime.now())) {
      _message('Nhập đủ nội dung và chọn thời gian ở tương lai.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = widget.reminder == null
          ? await widget.repository.create(title: title, body: body, scheduledAt: _scheduledAt)
          : await widget.repository.update(widget.reminder!.id, title: title, body: body, scheduledAt: _scheduledAt);
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.replaceFirst('Exception: ', '')), backgroundColor: error ? Colors.red : null),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.reminder == null ? 'Tạo nhắc nhở' : 'Chỉnh sửa nhắc nhở', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              const SizedBox(height: 12),
              TextField(controller: _body, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Nội dung')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Ngày nhắc'),
                trailing: TextButton(onPressed: _pickDate, child: Text(_dateLabel(_scheduledAt))),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Giờ nhắc'),
                trailing: TextButton(onPressed: _pickTime, child: Text(_timeLabel(_scheduledAt))),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Đang lưu...' : 'Lưu nhắc nhở')),
              ),
            ],
          ),
        ),
      );
}

TimeOfDay _timeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.tryParse(parts.first) ?? 8, minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
}

String _formatTime(TimeOfDay value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _timeLabel(DateTime value) => _formatTime(TimeOfDay.fromDateTime(value));

String _dateLabel(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTimeLabel(DateTime? value) => value == null ? 'Chưa có thời gian' : '${_dateLabel(value)} · ${_timeLabel(value)}';

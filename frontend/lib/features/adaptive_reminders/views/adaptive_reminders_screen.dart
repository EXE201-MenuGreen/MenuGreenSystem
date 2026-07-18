import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/reminder_models.dart';
import '../repositories/reminder_repository.dart';

part 'adaptive_reminder_widgets_part.dart';

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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
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

  Future<void> _addOfficePreset({required bool water}) async {
    try {
      await _repository.create(
        title: water ? 'Uống nước' : 'Vận động giãn cơ',
        body: water ? 'Uống một cốc nước để duy trì tập trung.' : 'Đứng dậy và đi bộ hoặc giãn cơ 5 phút.',
        scheduledAt: DateTime.now().add(Duration(hours: water ? 2 : 1)),
        repeatIntervalMinutes: water ? 120 : 60,
      );
      if (mounted) _message('Đã bật nhắc nhở ${water ? 'uống nước mỗi 2 giờ' : 'vận động mỗi giờ'}.');
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = 'Không thể tải nhắc nhở. Vui lòng thử lại.');
        _message(error.toString(), error: true);
      }
    }
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
                    repeatIntervalMinutes: item.repeatIntervalMinutes,
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
            : profile == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _loadError ?? 'Không thể tải dữ liệu nhắc nhở.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
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
                    time: profile.optimalBreakfastTime,
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
                      Expanded(child: Text('Lịch nhắc tùy chỉnh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      Text('${_reminders.length} lịch', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(avatar: const Icon(Icons.water_drop_outlined, size: 18), label: const Text('Nước / 2 giờ'), onPressed: () => _addOfficePreset(water: true)),
                      ActionChip(avatar: const Icon(Icons.directions_walk_outlined, size: 18), label: const Text('Giãn cơ / 1 giờ'), onPressed: () => _addOfficePreset(water: false)),
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



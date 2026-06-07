import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/notification_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _repository = NotificationRepository();
  NotificationSettings? _settings;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final settings = await _repository.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings ??
          NotificationSettings(
            mealReminderEnabled: true,
            mealReminderOffsetMinutes: 30,
            prepReminderEnabled: true,
            prepReminderOffsetMinutes: 20,
            inAppEnabled: true,
            pushEnabled: false,
          );
      _loading = false;
    });
  }

  Future<void> _save() async {
    final current = _settings;
    if (current == null) return;
    setState(() => _saving = true);
    final saved = await _repository.updateSettings(current);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved != null) _settings = saved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved != null ? 'Đã lưu cài đặt thông báo.' : 'Không lưu được cài đặt.'),
      ),
    );
  }

  void _patch(NotificationSettings Function(NotificationSettings s) fn) {
    final current = _settings;
    if (current == null) return;
    setState(() => _settings = fn(current));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Nhắc nhở bữa ăn được lưu trên server. Push khi app đóng sẽ bổ sung sau.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Nhắc giờ ăn'),
                  value: _settings!.mealReminderEnabled,
                  onChanged: (v) => _patch((s) => NotificationSettings(
                        mealReminderEnabled: v,
                        mealReminderOffsetMinutes: s.mealReminderOffsetMinutes,
                        prepReminderEnabled: s.prepReminderEnabled,
                        prepReminderOffsetMinutes: s.prepReminderOffsetMinutes,
                        inAppEnabled: s.inAppEnabled,
                        pushEnabled: s.pushEnabled,
                      )),
                ),
                ListTile(
                  title: const Text('Nhắc trước giờ ăn (phút)'),
                  subtitle: Slider(
                    min: 5,
                    max: 120,
                    divisions: 23,
                    value: _settings!.mealReminderOffsetMinutes.toDouble().clamp(5, 120),
                    label: '${_settings!.mealReminderOffsetMinutes} phút',
                    onChanged: _settings!.mealReminderEnabled
                        ? (v) => _patch((s) => NotificationSettings(
                              mealReminderEnabled: s.mealReminderEnabled,
                              mealReminderOffsetMinutes: v.round(),
                              prepReminderEnabled: s.prepReminderEnabled,
                              prepReminderOffsetMinutes: s.prepReminderOffsetMinutes,
                              inAppEnabled: s.inAppEnabled,
                              pushEnabled: s.pushEnabled,
                            ))
                        : null,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Nhắc chuẩn bị nấu'),
                  value: _settings!.prepReminderEnabled,
                  onChanged: (v) => _patch((s) => NotificationSettings(
                        mealReminderEnabled: s.mealReminderEnabled,
                        mealReminderOffsetMinutes: s.mealReminderOffsetMinutes,
                        prepReminderEnabled: v,
                        prepReminderOffsetMinutes: s.prepReminderOffsetMinutes,
                        inAppEnabled: s.inAppEnabled,
                        pushEnabled: s.pushEnabled,
                      )),
                ),
                ListTile(
                  title: const Text('Nhắc trước khi nấu (phút)'),
                  subtitle: Slider(
                    min: 5,
                    max: 90,
                    divisions: 17,
                    value: _settings!.prepReminderOffsetMinutes.toDouble().clamp(5, 90),
                    label: '${_settings!.prepReminderOffsetMinutes} phút',
                    onChanged: _settings!.prepReminderEnabled
                        ? (v) => _patch((s) => NotificationSettings(
                              mealReminderEnabled: s.mealReminderEnabled,
                              mealReminderOffsetMinutes: s.mealReminderOffsetMinutes,
                              prepReminderEnabled: s.prepReminderEnabled,
                              prepReminderOffsetMinutes: v.round(),
                              inAppEnabled: s.inAppEnabled,
                              pushEnabled: s.pushEnabled,
                            ))
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu cài đặt'),
                ),
              ],
            ),
    );
  }
}

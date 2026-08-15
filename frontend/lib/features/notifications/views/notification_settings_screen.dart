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
        content: Text(
          saved != null
              ? 'Đã cập nhật cài đặt thông báo thành công.'
              : 'Không thể lưu cài đặt thông báo. Vui lòng thử lại sau.',
        ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Nhắc nhở'),
                const SizedBox(height: 8),
                _buildSettingCard(
                  title: 'Nhắc giờ ăn',
                  subtitle: 'Nhận thông báo trước khi đến giờ ăn',
                  icon: Icons.restaurant_outlined,
                  iconColor: AppColors.primary,
                  trailing: Switch(
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
                ),
                if (_settings!.mealReminderEnabled) ...[
                  _buildSliderTile(
                    title: 'Nhắc trước giờ ăn',
                    value: _settings!.mealReminderOffsetMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (v) => _patch((s) => NotificationSettings(
                          mealReminderEnabled: s.mealReminderEnabled,
                          mealReminderOffsetMinutes: v.round(),
                          prepReminderEnabled: s.prepReminderEnabled,
                          prepReminderOffsetMinutes: s.prepReminderOffsetMinutes,
                          inAppEnabled: s.inAppEnabled,
                          pushEnabled: s.pushEnabled,
                        )),
                  ),
                ],
                const SizedBox(height: 8),
                _buildSettingCard(
                  title: 'Nhắc chuẩn bị nấu',
                  subtitle: 'Nhận thông báo trước khi bắt đầu nấu',
                  icon: Icons.kitchen_outlined,
                  iconColor: Colors.orange,
                  trailing: Switch(
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
                ),
                if (_settings!.prepReminderEnabled) ...[
                  _buildSliderTile(
                    title: 'Nhắc trước khi nấu',
                    value: _settings!.prepReminderOffsetMinutes.toDouble(),
                    min: 5,
                    max: 90,
                    divisions: 17,
                    onChanged: (v) => _patch((s) => NotificationSettings(
                          mealReminderEnabled: s.mealReminderEnabled,
                          mealReminderOffsetMinutes: s.mealReminderOffsetMinutes,
                          prepReminderEnabled: s.prepReminderEnabled,
                          prepReminderOffsetMinutes: v.round(),
                          inAppEnabled: s.inAppEnabled,
                          pushEnabled: s.pushEnabled,
                        )),
                  ),
                ],
                const SizedBox(height: 16),
                _buildSectionHeader('Kênh nhận thông báo'),
                const SizedBox(height: 8),
                _buildSettingCard(
                  title: 'Thông báo trong app',
                  subtitle: 'Hiển thị thông báo khi đang sử dụng app',
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.blue,
                  trailing: Switch(
                    value: _settings!.inAppEnabled,
                    onChanged: (v) => _patch((s) => NotificationSettings(
                          mealReminderEnabled: s.mealReminderEnabled,
                          mealReminderOffsetMinutes: s.mealReminderOffsetMinutes,
                          prepReminderEnabled: s.prepReminderEnabled,
                          prepReminderOffsetMinutes: s.prepReminderOffsetMinutes,
                          inAppEnabled: v,
                          pushEnabled: s.pushEnabled,
                        )),
                  ),
                ),
                _buildSettingCard(
                  title: 'Thông báo đẩy',
                  subtitle: 'Nhận thông báo ngay cả khi app đóng',
                  icon: Icons.phone_android_outlined,
                  iconColor: Colors.green,
                  trailing: Switch(
                    value: _settings!.pushEnabled,
                    onChanged: (v) => _patch((s) => NotificationSettings(
                          mealReminderEnabled: s.mealReminderEnabled,
                          mealReminderOffsetMinutes: s.mealReminderOffsetMinutes,
                          prepReminderEnabled: s.prepReminderEnabled,
                          prepReminderOffsetMinutes: s.prepReminderOffsetMinutes,
                          inAppEnabled: s.inAppEnabled,
                          pushEnabled: v,
                        )),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Lưu cài đặt',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.round()} phút',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nhắc nhở bữa ăn được lưu trên server. Push notification khi app đóng sẽ hoạt động sau khi bạn bật quyền trong cài đặt thiết bị.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

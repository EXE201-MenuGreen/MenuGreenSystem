part of 'adaptive_reminders_screen.dart';

class _ProfileTimeTile extends StatelessWidget {
  const _ProfileTimeTile({
    required this.icon,
    required this.title,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.schedule),
        label: Text(time),
      ),
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
      leading: const Icon(
        Icons.notifications_active_outlined,
        color: AppColors.primary,
      ),
      title: Text(reminder.title),
      subtitle: Text(
        '${_dateTimeLabel(reminder.scheduledAt)}${reminder.repeatIntervalMinutes == null ? '' : ' · Lặp mỗi ${reminder.repeatIntervalMinutes} phút'}${reminder.body.isEmpty ? '' : '\n${reminder.body}'}',
      ),
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
              PopupMenuItem(
                value: 'snooze15',
                child: Text('Nhắc lại sau 15 phút'),
              ),
              PopupMenuItem(
                value: 'snooze30',
                child: Text('Nhắc lại sau 30 phút'),
              ),
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
  bool _showValidationErrors = false;
  ReminderValidationResult _validation = const ReminderValidationResult();

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _title = TextEditingController(text: reminder?.title ?? 'Nhắc giờ ăn');
    _body = TextEditingController(
      text: reminder?.body ?? 'Đến giờ ghi nhật ký bữa ăn.',
    );
    _scheduledAt =
        reminder?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    _title.addListener(_validateAfterFirstSubmit);
    _body.addListener(_validateAfterFirstSubmit);
  }

  @override
  void dispose() {
    _title.removeListener(_validateAfterFirstSubmit);
    _body.removeListener(_validateAfterFirstSubmit);
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _validateAfterFirstSubmit() {
    if (!_showValidationErrors || !mounted) return;
    _validateInput();
  }

  ReminderValidationResult _validateInput() {
    final result = validateReminderInput(
      title: _title.text,
      body: _body.text,
      scheduledAt: _scheduledAt,
      now: DateTime.now(),
    );
    setState(() => _validation = result);
    return result;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(DateTime.now())
          ? DateTime.now()
          : _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(
        () => _scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          _scheduledAt.hour,
          _scheduledAt.minute,
        ),
      );
      if (_showValidationErrors) _validateInput();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time != null && mounted) {
      setState(
        () => _scheduledAt = DateTime(
          _scheduledAt.year,
          _scheduledAt.month,
          _scheduledAt.day,
          time.hour,
          time.minute,
        ),
      );
      if (_showValidationErrors) _validateInput();
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    _showValidationErrors = true;
    final validation = _validateInput();
    if (!validation.isValid) {
      _message(validation.firstError!, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = widget.reminder == null
          ? await widget.repository.create(
              title: title,
              body: body,
              scheduledAt: _scheduledAt,
            )
          : await widget.repository.update(
              widget.reminder!.id,
              title: title,
              body: body,
              scheduledAt: _scheduledAt,
            );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text.replaceFirst('Exception: ', '')),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reminder == null ? 'Tạo nhắc nhở' : 'Chỉnh sửa nhắc nhở',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            inputFormatters: [
              LengthLimitingTextInputFormatter(reminderTitleMaxLength),
            ],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Tiêu đề',
              errorText: _showValidationErrors ? _validation.titleError : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            inputFormatters: [
              LengthLimitingTextInputFormatter(reminderBodyMaxLength),
            ],
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Nội dung',
              errorText: _showValidationErrors ? _validation.bodyError : null,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Ngày nhắc'),
            trailing: TextButton(
              onPressed: _pickDate,
              child: Text(_dateLabel(_scheduledAt)),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Giờ nhắc'),
            trailing: TextButton(
              onPressed: _pickTime,
              child: Text(_timeLabel(_scheduledAt)),
            ),
          ),
          if (_showValidationErrors && _validation.scheduleError != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validation.scheduleError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu nhắc nhở'),
            ),
          ),
        ],
      ),
    ),
  );
}

TimeOfDay _timeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 8,
    minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
}

String _formatTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _timeLabel(DateTime value) => _formatTime(TimeOfDay.fromDateTime(value));

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTimeLabel(DateTime? value) => value == null
    ? 'Chưa có thời gian'
    : '${_dateLabel(value)} · ${_timeLabel(value)}';

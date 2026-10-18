import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import 'providers/task_providers.dart';

/// Title, optional notes and due date. Judge inserts a draft row.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _due;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _judge() async {
    final title = _title.text.trim();
    if (title.isEmpty || title.length > 200) {
      setState(() => _error = 'Use a title of 1 to 200 characters.');
      return;
    }
    final notes = _notes.text.trim();
    if (notes.length > 1000) {
      setState(() => _error = 'Keep the notes to 1000 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(insertDraftProvider)(
        title: title,
        notes: notes.isEmpty ? null : notes,
        dueAt: _due,
      );
      ref.invalidate(tasksProvider);
      if (mounted) context.go('/quests/$id');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save the draft. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = _due?.toLocal();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text('Add a quest', style: AppText.h1),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.s12),
            QButton(
              label: due == null ? 'Add a due date' : 'Due ${due.day}/${due.month}',
              variant: QButtonVariant.secondary,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _due ?? DateTime.now(),
                );
                if (picked != null) setState(() => _due = picked);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.s20),
            QButton(label: 'Judge', loading: _busy, onPressed: _busy ? null : _judge),
          ],
        ),
      ),
    );
  }
}

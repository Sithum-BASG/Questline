import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/clay.dart';
import 'providers/task_providers.dart';
import '../onboarding/onboarding_skip_button.dart';

/// Title, optional notes and due date. Judge inserts a draft row.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key, this.onboarding = false, this.bossId, this.raidId});

  /// Onboarding saves the draft and lets the first-task screen show the judgement.
  final bool onboarding;

  /// When set, the draft is created under this boss.
  final String? bossId;

  /// Party raid or guild battle this task fights.
  final String? raidId;

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
        bossId: widget.bossId,
        raidId: widget.raidId,
      );
      ref.invalidate(tasksProvider);
      if (!mounted) return;
      if (widget.onboarding) return;
      context.go('/quests/$id');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save the draft. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _due ?? DateTime.now(),
    );
    if (picked != null) setState(() => _due = picked);
  }

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final due = _due?.toLocal();
    final today = _today;
    final tomorrow = today.add(const Duration(days: 1));
    final isToday = _sameDay(due, today);
    final isTomorrow = _sameDay(due, tomorrow);
    final isCustom = due != null && !isToday && !isTomorrow;
    final canClose = !widget.onboarding && Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.s32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('New quest', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
                  ),
                ),
                if (widget.onboarding) const OnboardingSkipButton(),
                if (canClose)
                  ClayIconButton(
                    icon: Icons.close_rounded,
                    size: 40,
                    iconSize: 18,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Clay(
              padding: const EdgeInsets.fromLTRB(16, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        image: true,
                        label: 'Stat not judged yet',
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8ECF2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC3CAD6), width: 1.6),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.inkFaint),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('QUEST', style: AppText.label),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _title,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: null,
                              style: AppText.h2.copyWith(fontSize: 19, height: 25 / 19, fontWeight: FontWeight.w600),
                              decoration: InputDecoration.collapsed(
                                hintText: "What's the quest?",
                                hintStyle: AppText.h2.copyWith(
                                  fontSize: 19,
                                  height: 25 / 19,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.placeholder,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 66),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.notes_rounded, size: 16, color: AppColors.inkFaint),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _notes,
                                textCapitalization: TextCapitalization.sentences,
                                maxLines: null,
                                style: AppText.body.copyWith(fontSize: 14, height: 20 / 14),
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Add notes (optional)',
                                  hintStyle: AppText.body.copyWith(
                                    fontSize: 14,
                                    height: 20 / 14,
                                    color: AppColors.placeholder,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'DUE', style: AppText.label),
                  TextSpan(
                    text: '  · optional',
                    style: AppText.caption.copyWith(color: AppColors.inkFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _DueChip(label: 'None', selected: due == null, onTap: () => setState(() => _due = null)),
                  _DueChip(label: 'Today', selected: isToday, onTap: () => setState(() => _due = today)),
                  _DueChip(label: 'Tomorrow', selected: isTomorrow, onTap: () => setState(() => _due = tomorrow)),
                  _DueChip(
                    label: isCustom ? '${_wd[due.weekday - 1]} ${due.day} ${_mo[due.month - 1]}' : 'Pick a date',
                    icon: Icons.calendar_today_rounded,
                    selected: isCustom,
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Well(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.tealDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppText.bodySmall,
                        children: [
                          const TextSpan(text: 'The Judge sets the '),
                          TextSpan(
                            text: 'stat, difficulty and time',
                            style: AppText.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: '. You can change the stat after.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s16),
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: AppSpacing.s32),
            QButton(
              label: 'Judge',
              icon: Icons.auto_awesome_rounded,
              loading: _busy,
              onPressed: _busy ? null : _judge,
            ),
          ],
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Due $label',
        excludeSemantics: true,
        child: Clay(
          kind: selected ? ClayKind.teal : ClayKind.control,
          radius: 22,
          height: 44,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? AppColors.white : AppColors.ink),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppText.title.copyWith(fontSize: 14, color: selected ? AppColors.white : AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../models/task.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId;
  final String? projectId;

  const TaskFormScreen({super.key, this.taskId, this.projectId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  DateTime _selectedDate = DateTime.now();
  String _status = 'pending';
  String _priority = 'medium';
  bool _isEditing = false;

  static const _statuses = [
    ('pending', '⏳ Pending', Color(0xFFF59E0B)),
    ('in_progress', '🔨 In Progress', Color(0xFF6366F1)),
    ('review', '👁️ Review', Color(0xFF8B5CF6)),
    ('done', '✅ Done', Color(0xFF10B981)),
    ('delivered', '📦 Delivered', Color(0xFF06B6D4)),
  ];

  static const _priorities = [
    ('low', '🟢 Low', Color(0xFF22C55E)),
    ('medium', '🟡 Medium', Color(0xFFF59E0B)),
    ('high', '🟠 High', Color(0xFFF97316)),
    ('urgent', '🔴 Urgent', Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _costController = TextEditingController();

    if (widget.taskId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final task = ref
            .read(allTasksProvider)
            .where((t) => t.id == widget.taskId)
            .firstOrNull;
        if (task != null) {
          _titleController.text = task.title;
          _descriptionController.text = task.description;
          _costController.text = task.cost.toString();
          setState(() {
            _selectedDate = task.date;
            _status = task.status;
            _priority = task.priority;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: const Color(0xFF1A1A2E),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;

    if (_isEditing) {
      final task =
          ref.read(allTasksProvider).where((t) => t.id == widget.taskId).first;
      final updated = Task(
        id: task.id,
        projectId: task.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: cost,
        date: _selectedDate,
        status: _status,
        createdAt: task.createdAt,
        priority: _priority,
        completedAt: _status == 'done' && task.completedAt == null
            ? DateTime.now()
            : task.completedAt,
        deliveredAt: _status == 'delivered' && task.deliveredAt == null
            ? DateTime.now()
            : task.deliveredAt,
      );
      await ref.read(allTasksProvider.notifier).update(updated);
    } else {
      await ref.read(allTasksProvider.notifier).add(
            projectId: widget.projectId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            cost: cost,
            date: _selectedDate,
            status: _status,
            priority: _priority,
          );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Task Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Homepage design, API integration',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 24),
              _sectionLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Details about what was done...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              _sectionLabel('Cost *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Cost is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _sectionLabel('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232340),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('Priority'),
              const SizedBox(height: 8),
              Row(
                children: _priorities
                    .map((p) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _chipButton(
                              label: p.$2,
                              value: p.$1,
                              color: p.$3,
                              selected: _priority == p.$1,
                              onTap: () => setState(() => _priority = p.$1),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              _sectionLabel('Status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _statuses
                    .map((s) => _chipButton(
                          label: s.$2,
                          value: s.$1,
                          color: s.$3,
                          selected: _status == s.$1,
                          onTap: () => setState(() => _status = s.$1),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update Task' : 'Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipButton({
    required String label,
    required String value,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/providers.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final String? clientId;

  const ProjectFormScreen({super.key, this.projectId, this.clientId});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _status = 'active';
  String _currency = 'EGP';
  String? _selectedClientId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedClientId = widget.clientId;

    if (widget.projectId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final project = ref
            .read(allProjectsProvider)
            .where(
              (p) => p.id == widget.projectId,
            )
            .firstOrNull;
        if (project != null) {
          _nameController.text = project.name;
          _descriptionController.text = project.description;
          setState(() {
            _status = project.status;
            _currency = project.currency;
            _selectedClientId = project.clientId;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    if (_isEditing) {
      final project = ref
          .read(allProjectsProvider)
          .where(
            (p) => p.id == widget.projectId,
          )
          .first;
      final updated = project.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        currency: _currency,
      );
      await ref.read(allProjectsProvider.notifier).update(updated);
    } else {
      await ref.read(allProjectsProvider.notifier).add(
            clientId: _selectedClientId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            status: _status,
            currency: _currency,
          );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Project' : 'New Project',
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
              // Client selector
              if (!_isEditing) ...[
                _sectionLabel('Client *'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: const InputDecoration(
                    hintText: 'Select client',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  items: clients.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedClientId = v),
                  validator: (v) => v == null ? 'Please select a client' : null,
                ),
                const SizedBox(height: 24),
              ],

              _sectionLabel('Project Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Website Redesign',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),

              _sectionLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'What is this project about?',
                  prefixIcon: Icon(Icons.description_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              _sectionLabel('Status'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusChip('active', 'Active'),
                  const SizedBox(width: 8),
                  _statusChip('on-hold', 'On Hold'),
                  const SizedBox(width: 8),
                  _statusChip('completed', 'Completed'),
                ],
              ),
              const SizedBox(height: 24),

              _sectionLabel('Currency'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _currencyChip('EGP'),
                  const SizedBox(width: 8),
                  _currencyChip('USD'),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update Project' : 'Create Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _currencyChip(String value) {
    final selected = _currency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currency = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.5),
            ),
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
        color: Colors.white.withOpacity(0.5),
        letterSpacing: 0.5,
      ),
    );
  }
}

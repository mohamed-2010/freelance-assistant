import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/providers.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.clientId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final client = ref
            .read(clientsProvider)
            .where(
              (c) => c.id == widget.clientId,
            )
            .firstOrNull;
        if (client != null) {
          _nameController.text = client.name;
          _contactController.text = client.contact;
          _notesController.text = client.notes;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final client = ref
          .read(clientsProvider)
          .where(
            (c) => c.id == widget.clientId,
          )
          .first;
      final updated = client.copyWith(
        name: _nameController.text.trim(),
        contact: _contactController.text.trim(),
        notes: _notesController.text.trim(),
      );
      await ref.read(clientsProvider.notifier).update(updated);
    } else {
      await ref.read(clientsProvider.notifier).add(
            name: _nameController.text.trim(),
            contact: _contactController.text.trim(),
            notes: _notesController.text.trim(),
          );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Client' : 'New Client',
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
              _sectionLabel('Client Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ahmed Corp',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),
              _sectionLabel('Contact Info'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  hintText: 'Email or phone number',
                  prefixIcon: Icon(Icons.contact_mail_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              _sectionLabel('Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Any notes about this client...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update Client' : 'Add Client'),
                ),
              ),
            ],
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

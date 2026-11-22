import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'auth.dart';
import 'db.dart';
import 'sections.dart';

class EditScreen extends StatefulWidget {
  final Section section;
  final Rec? record;
  const EditScreen({super.key, required this.section, this.record});
  @override
  State<EditScreen> createState() => _EditState();
}

class _EditState extends State<EditScreen> {
  final _f = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  final List<Rec> _atts = []; // існуючі (з id) та нові (new=true)
  final List<int> _removed = [];

  Section get s => widget.section;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _c = {
      for (final f in s.fields)
        f.key: TextEditingController(
            text: f.type == FType.date
                ? (r != null ? toUi(r[f.key]) : DateFormat('dd.MM.yyyy').format(DateTime.now()))
                : '${r?[f.key] ?? ''}')
    };
    if (r != null) {
      Db.attachments(s.table, r['id'] as int).then((a) => setState(() => _atts.addAll(a.map((e) => {...e}))));
    }
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(toIso(c.text)) ?? DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
    if (d != null) c.text = DateFormat('dd.MM.yyyy').format(d);
  }

  Future<void> _pickFiles() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (r == null) return;
    setState(() {
      for (final f in r.files) {
        if (f.path != null) _atts.add({'name': f.name, 'path': f.path, 'new': true});
      }
    });
  }

  Future<void> _save() async {
    if (!_f.currentState!.validate()) return;
    final data = {
      for (final f in s.fields) f.key: f.type == FType.date ? toIso(_c[f.key]!.text) : _c[f.key]!.text.trim()
    };
    final uid = Auth.userId!;
    int id;
    if (widget.record == null) {
      id = await Db.insert(s, uid, data);
    } else {
      id = widget.record!['id'] as int;
      await Db.update(s, id, data);
    }
    for (final r in _removed) {
      await Db.deleteAttachment(r);
    }
    for (final a in _atts.where((a) => a['new'] == true)) {
      await Db.addAttachment(uid, s.table, id, a['name'], a['path']);
    }
    if (mounted) Navigator.pop(context);
  }

  bool _isImage(String p) => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(p.split('.').last.toLowerCase());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.record == null ? 'Новий запис' : 'Редагування'),
            actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)]),
        body: Form(
          key: _f,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final f in s.fields) ...[
              TextFormField(
                controller: _c[f.key],
                readOnly: f.type == FType.date,
                maxLines: f.type == FType.multiline ? 4 : 1,
                onTap: f.type == FType.date ? () => _pickDate(_c[f.key]!) : null,
                decoration: InputDecoration(
                    labelText: f.label,
                    border: const OutlineInputBorder(),
                    suffixIcon: f.type == FType.date ? const Icon(Icons.calendar_today) : null),
                validator: f == s.fields.first ? (v) => (v == null || v.trim().isEmpty) ? 'Обов’язкове поле' : null : null,
              ),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Text('Файли (фото, PDF…)', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.attach_file), label: const Text('Додати')),
            ]),
            for (final a in _atts)
              Card(
                child: ListTile(
                  leading: _isImage(a['path'])
                      ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(File(a['path']), width: 48, height: 48, fit: BoxFit.cover))
                      : const Icon(Icons.insert_drive_file, size: 40),
                  title: Text(a['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => OpenFilex.open(a['path']),
                  trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                            if (a['id'] != null) _removed.add(a['id'] as int);
                            _atts.remove(a);
                          })),
                ),
              ),
          ]),
        ),
      );
}

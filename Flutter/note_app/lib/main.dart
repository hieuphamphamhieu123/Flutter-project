import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NotesApp());
}

class Note {
  final String id;
  String title;
  String content;
  final DateTime createdAt;

  Note({required this.id, required this.title, required this.content, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  static Note fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotesProvider extends ChangeNotifier {
  static const _storageKey = 'notes_v1';
  final List<Note> _notes = [];
  SharedPreferences? _prefs;

  List<Note> get notes => List.unmodifiable(_notes);

  Future<void> loadNotes() async {
    _prefs = await SharedPreferences.getInstance();
    final list = _prefs!.getStringList(_storageKey) ?? [];
    _notes.clear();
    for (final s in list) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        _notes.add(Note.fromJson(map));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    final list = _notes.map((n) => jsonEncode(n.toJson())).toList();
    await _prefs!.setStringList(_storageKey, list);
  }

  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    await _save();
    notifyListeners();
  }

  Future<void> updateNote(String id, {String? title, String? content}) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return;
    final n = _notes[i];
    if (title != null) n.title = title;
    if (content != null) n.content = content;
    await _save();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _save();
    notifyListeners();
  }
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesProvider()..loadNotes(),
      child: MaterialApp(
        title: 'Notes',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const NotesHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class NotesHomePage extends StatelessWidget {
  const NotesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final notes = provider.notes;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet. Tap + to create one.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final n = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(n.title.isEmpty ? '(No title)' : n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      n.content.isEmpty ? '—' : n.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await provider.deleteNote(n.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
                      },
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditor(note: n))),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditor())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteEditor extends StatefulWidget {
  final Note? note;
  const NoteEditor({super.key, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<NotesProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    setState(() => _saving = true);
    if (widget.note == null) {
      final note = Note(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, content: content);
      await provider.addNote(note);
    } else {
      await provider.updateNote(widget.note!.id, title: title, content: content);
    }
    setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: _saving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: 'Content', border: OutlineInputBorder()),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class Todo {
  final String id;
  final String title;
  bool done;

  Todo({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  static Todo fromJson(Map<String, dynamic> j) => Todo(id: j['id'], title: j['title'], done: j['done'] ?? false);
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const TodoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  late SharedPreferences _prefs;
  bool _loading = true;

  static const String _storageKey = 'todos_v1';

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getStringList(_storageKey) ?? [];
    _todos.clear();
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        _todos.add(Todo.fromJson(map));
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  Future<void> _saveTodos() async {
    final list = _todos.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_storageKey, list);
  }

  void _addTodo(String title) {
    if (title.trim().isEmpty) return;
    final todo = Todo(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title.trim());
    setState(() {
      _todos.insert(0, todo);
      _controller.clear();
    });
    _saveTodos();
  }

  void _toggleDone(int index) {
    setState(() {
      _todos[index].done = !_todos[index].done;
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    final removed = _todos.removeAt(index);
    setState(() {});
    _saveTodos();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${removed.title}"')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo')), 
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(hintText: 'Add a new task', border: OutlineInputBorder()),
                          onSubmitted: (v) => _addTodo(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addTodo(_controller.text),
                        child: const Text('Add'),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _todos.isEmpty
                      ? const Center(child: Text('No tasks yet. Add one above.'))
                      : ListView.builder(
                          itemCount: _todos.length,
                          itemBuilder: (context, index) {
                            final todo = _todos[index];
                            return Dismissible(
                              key: Key(todo.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteTodo(index),
                              child: ListTile(
                                leading: Checkbox(value: todo.done, onChanged: (_) => _toggleDone(index)),
                                title: Text(
                                  todo.title,
                                  style: TextStyle(decoration: todo.done ? TextDecoration.lineThrough : null),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteTodo(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTodo(_controller.text),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

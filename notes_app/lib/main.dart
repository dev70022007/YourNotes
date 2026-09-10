import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const YourNotes());
}

class YourNotes extends StatelessWidget {
  const YourNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YourNotes',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> notes = [];

  // Save notes
  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('notes', notes);
  }

  // Load notes
  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final savedNotes = prefs.getStringList('notes');

    if (savedNotes != null) {
      setState(() {
        notes = savedNotes;
      });
    }
  }

  // Runs when HomeScreen starts
  @override
  void initState() {
    super.initState();

    loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YourNotes')),

      body: notes.isEmpty
          ? const Center(
              child: Text('No notes yet', style: TextStyle(fontSize: 20)),
            )
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(notes[index]),

                    // Edit note
                    onTap: () async {
                      final editedNote = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoteScreen(existingNote: notes[index]),
                        ),
                      );

                      if (editedNote != null) {
                        setState(() {
                          notes[index] = editedNote;
                        });

                        await saveNotes();
                      }
                    },

                    // Delete note
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        setState(() {
                          notes.removeAt(index);
                        });

                        await saveNotes();
                      },
                    ),
                  ),
                );
              },
            ),

      // Add new note
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final savedNote = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteScreen()),
          );

          if (savedNote != null) {
            setState(() {
              notes.add(savedNote);
            });

            await saveNotes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteScreen extends StatefulWidget {
  final String? existingNote;

  const NoteScreen({super.key, this.existingNote});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    noteController.text = widget.existingNote ?? '';
  }

  @override
  void dispose() {
    noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, noteController.text);
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Write your note here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 10,
        ),
      ),
    );
  }
}

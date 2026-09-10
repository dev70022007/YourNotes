import 'dart:convert';

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

class Note {
  String title;
  String content;

  Note({required this.title, required this.content});

  Map<String, dynamic> toMap() {
    return {'title': title, 'content': content};
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(title: map['title'], content: map['content']);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];

  TextEditingController searchController = TextEditingController();

  List<Note> get filteredNotes {
    if (searchController.text.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      return note.title.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          note.content.toLowerCase().contains(
            searchController.text.toLowerCase(),
          );
    }).toList();
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> savedNotes = [];

    for (Note note in notes) {
      savedNotes.add(jsonEncode(note.toMap()));
    }

    await prefs.setStringList('notes', savedNotes);
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final savedNotes = prefs.getStringList('notes');

    if (savedNotes != null) {
      List<Note> loadedNotes = [];

      for (String noteString in savedNotes) {
        Map<String, dynamic> noteMap = jsonDecode(noteString);

        loadedNotes.add(Note.fromMap(noteMap));
      }

      setState(() {
        notes = loadedNotes;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    loadNotes();
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YourNotes')),

      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {});
              },

              decoration: const InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Notes list
          Expanded(
            child: notes.isEmpty
                ? const Center(
                    child: Text('No notes yet', style: TextStyle(fontSize: 20)),
                  )
                : filteredNotes.isEmpty
                ? const Center(
                    child: Text(
                      'No matching notes',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,

                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];

                      final originalIndex = notes.indexOf(note);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        child: ListTile(
                          // Note title
                          title: Text(note.title),

                          // Note content
                          subtitle: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Edit note
                          onTap: () async {
                            final editedNote = await Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) =>
                                    NoteScreen(existingNote: note),
                              ),
                            );

                            if (editedNote != null) {
                              setState(() {
                                notes[originalIndex] = editedNote;
                              });

                              await saveNotes();
                            }
                          },

                          // Delete note
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),

                            onPressed: () async {
                              setState(() {
                                notes.removeAt(originalIndex);
                              });

                              await saveNotes();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
  final Note? existingNote;

  const NoteScreen({super.key, this.existingNote});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController contentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.existingNote != null) {
      titleController.text = widget.existingNote!.title;

      contentController.text = widget.existingNote!.content;
    }
  }

  @override
  void dispose() {
    titleController.dispose();

    contentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),

        actions: [
          IconButton(
            onPressed: () {
              final note = Note(
                title: titleController.text,

                content: contentController.text,
              );

              Navigator.pop(context, note);
            },

            icon: const Icon(Icons.save),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: titleController,

              decoration: const InputDecoration(
                hintText: 'Title',

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: TextField(
                controller: contentController,

                decoration: const InputDecoration(
                  hintText: 'Write your note here...',

                  border: OutlineInputBorder(),
                ),

                maxLines: null,

                expands: true,

                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

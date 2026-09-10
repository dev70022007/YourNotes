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
  bool isPinned;
  DateTime lastEdited;

  Note({
    required this.title,
    required this.content,
    this.isPinned = false,
    DateTime? lastEdited,
  }) : lastEdited = lastEdited ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'isPinned': isPinned,
      'lastEdited': lastEdited.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'],
      content: map['content'],
      isPinned: map['isPinned'] ?? false,
      lastEdited: map['lastEdited'] != null
          ? DateTime.parse(map['lastEdited'])
          : DateTime.now(),
    );
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
    List<Note> result;

    if (searchController.text.isEmpty) {
      result = List.from(notes);
    } else {
      result = notes.where((note) {
        return note.title.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            note.content.toLowerCase().contains(
              searchController.text.toLowerCase(),
            );
      }).toList();
    }

    result.sort((a, b) {
      if (a.isPinned && !b.isPinned) {
        return -1;
      }

      if (!a.isPinned && b.isPinned) {
        return 1;
      }

      return 0;
    });

    return result;
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
      appBar: AppBar(
        title: const Text(
          'YourNotes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
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
                        elevation: 3,
                        color: note.isPinned ? Colors.amber.shade50 : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            note.title.isEmpty ? 'Untitled Note' : note.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.content.isEmpty
                                      ? 'No content'
                                      : note.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Last edited: ${note.lastEdited.day}/${note.lastEdited.month}/${note.lastEdited.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  note.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                ),
                                onPressed: () async {
                                  setState(() {
                                    note.isPinned = !note.isPinned;
                                  });

                                  await saveNotes();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete note?'),
                                        content: const Text(
                                          'This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete == true) {
                                    setState(() {
                                      notes.removeAt(originalIndex);
                                    });

                                    await saveNotes();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
        child: const Icon(Icons.add, size: 28),
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
              if (titleController.text.trim().isEmpty &&
                  contentController.text.trim().isEmpty) {
                return;
              }

              final note = Note(
                title: titleController.text,
                content: contentController.text,
                isPinned: widget.existingNote?.isPinned ?? false,
                lastEdited: DateTime.now(),
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
              decoration: InputDecoration(
                hintText: 'Title',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: InputDecoration(
                  hintText: 'Write your note here...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
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

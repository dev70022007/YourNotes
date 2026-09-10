import 'package:flutter/material.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YourNotes')),
      body: const Center(
        child: Text('No notes yet', style: TextStyle(fontSize: 20)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Note')),
      body: const Center(child: Text('Write your note here')),
    );
  }
}

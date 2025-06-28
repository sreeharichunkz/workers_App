import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'feedback_history_screen.dart'; // NEW PAGE

class FeedbackScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String teamId;

  const FeedbackScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.teamId,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Suggestion';
  String _message = '';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Suggestion',
    'Complaint',
    'Appreciation',
    'Other',
  ];

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    _formKey.currentState!.save();

    await FirebaseFirestore.instance.collection('feedbacks').add({
      'uid': widget.uid,
      'name': widget.name,
      'team_id': widget.teamId,
      'category': _category,
      'message': _message,
      'is_anonymous': _isAnonymous,
      'submitted_at': DateTime.now(),
      'response': null,
      'responded_at': null,
      'follow_up': null,
    });

    setState(() {
      _isSubmitting = false;
      _message = '';
      _isAnonymous = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted. Thank you!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Feedback")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Feedback Type',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your Message',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                    onSaved: (value) => _message = value!.trim(),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _isAnonymous,
                    onChanged: (value) => setState(() => _isAnonymous = value!),
                    title: const Text("Submit Anonymously"),
                    subtitle: const Text(
                      "Your name won't be shown to HR, but will be stored for internal reference.",
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label:
                        _isSubmitting
                            ? const CircularProgressIndicator()
                            : const Text('Submit'),
                    onPressed: _isSubmitting ? null : _submitFeedback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("View My Feedback History"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => FeedbackHistoryScreen(
                          uid: widget.uid,
                          name: widget.name,
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

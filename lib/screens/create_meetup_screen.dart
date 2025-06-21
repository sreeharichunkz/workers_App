import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateMeetupScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String teamId;

  const CreateMeetupScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.teamId,
  });

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  String type = 'Coffee';
  final locationController = TextEditingController();
  DateTime? selectedDateTime;
  int maxPeople = 2;
  bool isSubmitting = false;

  void _submit() async {
    final location = locationController.text.trim();

    if (location.isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (maxPeople < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Max people must be at least 2.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('meetups').add({
        'creator_uid': widget.uid,
        'creator_name': widget.name,
        'team_id': widget.teamId,
        'type': type,
        'location': location,
        'datetime': selectedDateTime,
        'max_people': maxPeople,
        'created_at': Timestamp.now(),
        'participants': [widget.uid], // 👈 creator counts as 1
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meetup created successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating meetup: $e")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Meetup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items:
                  ['Coffee', 'Lunch']
                      .map(
                        (val) => DropdownMenuItem(value: val, child: Text(val)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => type = val!),
              decoration: const InputDecoration(labelText: 'Meetup Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Max People: $maxPeople",
              style: const TextStyle(fontSize: 16),
            ),
            Slider(
              min: 2,
              max: 20,
              divisions: 18,
              label: "$maxPeople",
              value: maxPeople.toDouble(),
              onChanged: (val) => setState(() => maxPeople = val.toInt()),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDateTime == null
                    ? "Pick Date & Time"
                    : "${selectedDateTime!.toLocal()}",
              ),
              onPressed: _pickDateTime,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check),
                label: Text(isSubmitting ? "Creating..." : "Create Meetup"),
                onPressed: isSubmitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

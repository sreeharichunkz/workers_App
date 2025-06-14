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

  void _submit() async {
    if (locationController.text.isEmpty || selectedDateTime == null) return;

    await FirebaseFirestore.instance.collection('meetups').add({
      'creator_uid': widget.uid,
      'creator_name': widget.name,
      'team_id': widget.teamId,
      'type': type,
      'location': locationController.text,
      'datetime': selectedDateTime,
      'created_at': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Meetup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: Text(
                selectedDateTime == null
                    ? "Pick Date & Time"
                    : "${selectedDateTime!.toLocal()}",
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
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
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Create Meetup"),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

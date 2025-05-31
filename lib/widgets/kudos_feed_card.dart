import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class KudosFeedCard extends StatefulWidget {
  final String currentUid;
  final Map<String, dynamic> data;
  final String docId;

  const KudosFeedCard({
    super.key,
    required this.currentUid,
    required this.data,
    required this.docId,
  });

  @override
  State<KudosFeedCard> createState() => _KudosFeedCardState();
}

class _KudosFeedCardState extends State<KudosFeedCard> {
  bool showComments = false;
  final TextEditingController _commentController = TextEditingController();

  void _toggleReaction(String emoji) async {
    final reactions = Map<String, dynamic>.from(widget.data['reactions'] ?? {});
    final currentList = List<String>.from(reactions[emoji] ?? []);

    if (currentList.contains(widget.currentUid)) {
      currentList.remove(widget.currentUid);
    } else {
      currentList.add(widget.currentUid);
    }
    reactions[emoji] = currentList;

    await FirebaseFirestore.instance
        .collection('kudos')
        .doc(widget.docId)
        .update({'reactions': reactions});
  }

  void _addComment(String text) async {
    if (text.trim().isEmpty) return;

    final comment = {
      'uid': widget.currentUid,
      'name': widget.data['sender'], // You can fetch real name if needed
      'text': text.trim(),
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('kudos')
        .doc(widget.docId)
        .update({
          'comments': FieldValue.arrayUnion([comment]),
        });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final time = (data['timestamp'] as Timestamp?)?.toDate();
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final commentsRaw = data['comments'];
    final comments =
        (commentsRaw is List)
            ? commentsRaw
                .whereType<Map>()
                .map((c) => Map<String, dynamic>.from(c))
                .toList()
            : <Map<String, dynamic>>[];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data['sender']} sent kudos to ${data['receiver']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if ((data['message'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(data['message']),
              ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  timeago.format(time),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),

            // Reactions
            Wrap(
              spacing: 8,
              children:
                  ['👍', '❤️', '🎉', '😂'].map((emoji) {
                    final count = reactions[emoji]?.length ?? 0;
                    final reacted =
                        reactions[emoji]?.contains(widget.currentUid) ?? false;
                    return GestureDetector(
                      onTap: () => _toggleReaction(emoji),
                      child: Chip(
                        label: Text("$emoji $count"),
                        backgroundColor:
                            reacted
                                ? Colors.indigo.shade100
                                : Colors.grey.shade200,
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 10),

            // Always show comment input
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Write a comment...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _addComment(_commentController.text),
                ),
              ),
            ),

            // Toggle button for showing/hiding comments
            if (comments.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => showComments = !showComments),
                child: Text(
                  showComments ? 'Hide Comments' : '💬 Show Comments',
                ),
              ),

            // Display comments
            if (showComments)
              ...comments.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c['name'] ?? 'User'),
                  subtitle: Text(c['text'] ?? ''),
                  trailing: Text(
                    c['timestamp'] != null
                        ? timeago.format((c['timestamp'] as Timestamp).toDate())
                        : '',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

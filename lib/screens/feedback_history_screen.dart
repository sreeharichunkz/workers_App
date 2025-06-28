import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedbackHistoryScreen extends StatefulWidget {
  final String uid;
  final String name;

  const FeedbackHistoryScreen({
    super.key,
    required this.uid,
    required this.name,
  });

  @override
  State<FeedbackHistoryScreen> createState() => _FeedbackHistoryScreenState();
}

class _FeedbackHistoryScreenState extends State<FeedbackHistoryScreen> {
  List<DocumentSnapshot> _feedbacks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  void _loadFeedbacks() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('feedbacks')
            .where('uid', isEqualTo: widget.uid)
            .orderBy('submitted_at', descending: true)
            .get();

    if (!mounted) return;
    setState(() {
      _feedbacks = snapshot.docs;
      _loading = false;
    });

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['response'] != null && data['seen_response'] != true) {
        FirebaseFirestore.instance.collection('feedbacks').doc(doc.id).update({
          'seen_response': true,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("💬 New response from HR: \"${data['response']}\""),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _submitFollowUp(String docId, String reply) async {
    await FirebaseFirestore.instance.collection('feedbacks').doc(docId).update({
      'follow_up': reply,
      'followed_up_at': DateTime.now(),
    });

    if (!mounted) return;
    _loadFeedbacks();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Follow-up sent.")));
  }

  void _showReplyDialog(String docId) {
    String replyText = '';
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Send Follow-Up"),
            content: TextFormField(
              maxLines: 3,
              onChanged: (val) => replyText = val,
              decoration: const InputDecoration(
                hintText: "Type your follow-up message...",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                },
              ),
              ElevatedButton(
                child: const Text("Send"),
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  if (replyText.trim().isNotEmpty) {
                    _submitFollowUp(docId, replyText.trim());
                  }
                },
              ),
            ],
          ),
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Feedback History")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _feedbacks.isEmpty
              ? const Center(child: Text("No feedback submitted yet."))
              : ListView.builder(
                itemCount: _feedbacks.length,
                itemBuilder: (context, index) {
                  final doc = _feedbacks[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final category = data['category'] ?? 'General';
                  final message = data['message'] ?? '';
                  final response = data['response'];
                  final followUp = data['follow_up'];
                  final submittedAt = _parseDate(data['submitted_at']);
                  final respondedAt =
                      data['responded_at'] != null
                          ? _parseDate(data['responded_at'])
                          : null;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🗂 $category",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(message),
                          Text(
                            "Sent ${timeago.format(submittedAt)}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (response != null) ...[
                            const Divider(height: 20),
                            Row(
                              children: const [
                                Icon(
                                  Icons.shield,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Response from HR:",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              response,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (respondedAt != null)
                              Text(
                                "Responded ${timeago.format(respondedAt)}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 10),
                            if (followUp == null)
                              TextButton.icon(
                                icon: const Icon(Icons.reply),
                                label: const Text("Reply / Follow-up"),
                                onPressed: () => _showReplyDialog(doc.id),
                              )
                            else ...[
                              const SizedBox(height: 10),
                              const Text(
                                "Your Follow-up:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(followUp),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

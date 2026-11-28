import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Read-only availability check. Cached absence is not proof of deletion.
class PostAvailability extends StatefulWidget {
  const PostAvailability({
    super.key,
    required this.petId,
    required this.builder,
  });

  final Object? petId;
  final Widget Function(BuildContext, String?) builder;

  @override
  State<PostAvailability> createState() => _PostAvailabilityState();
}

class _PostAvailabilityState extends State<PostAvailability> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant PostAvailability oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.petId != widget.petId) _subscribe();
  }

  void _subscribe() {
    final id = widget.petId;
    _stream = id is String && id.trim().isNotEmpty && !id.contains('/')
        ? FirebaseFirestore.instance
              .collection('posts')
              .doc(id)
              .snapshots(includeMetadataChanges: true)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_stream == null) {
      return widget.builder(context, 'Unable to check post availability');
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      key: ValueKey(widget.petId),
      stream: _stream,
      builder: (context, snapshot) {
        final doc = snapshot.data;
        if (snapshot.hasError) {
          return widget.builder(context, 'Unable to check post availability');
        }
        if (doc == null ||
            doc.metadata.isFromCache ||
            doc.metadata.hasPendingWrites) {
          return widget.builder(context, 'Post availability not verified');
        }
        return widget.builder(context, doc.exists ? null : 'Post Removed');
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'animal_details_screen.dart';
import 'edit_post_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  static const Color _background = Color(0xFFFBE8BC);
  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _orange = Color(0xFFBF5700);
  static const Color _dark = Color(0xFF49270F);

  Future<void> _deletePost(BuildContext context, String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'This will permanently remove the post from '
          'the Home Feed and Map. Existing adoption '
          'applications, care records, and reports may '
          'still reference it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Firestore rules must also check post ownership.
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      // Remove this user's saved bookmark, if present.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedPosts')
            .doc(postId)
            .delete();
      } catch (_) {
        // Bookmark cleanup is not essential.
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete post: $error')));
    }
  }

  Future<void> _editPost(BuildContext context, String postId) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditPostScreen(postId: postId)),
    );

    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'My Posts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _background,
        foregroundColor: _dark,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your posts.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Unable to load posts: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _orange),
                  );
                }

                final posts = [...snapshot.data!.docs];

                // Show newest posts first.
                posts.sort((a, b) {
                  final aTime = a.data()['createdAt'];
                  final bTime = b.data()['createdAt'];

                  final aMs = aTime is Timestamp
                      ? aTime.millisecondsSinceEpoch
                      : 0;

                  final bMs = bTime is Timestamp
                      ? bTime.millisecondsSinceEpoch
                      : 0;

                  return bMs.compareTo(aMs);
                });

                if (posts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets_rounded, size: 60, color: _orange),
                          SizedBox(height: 14),
                          Text(
                            "You haven't created any posts yet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: _dark),
                          ),
                          SizedBox(height: 8),
                          Text('Use the Post tab to help an animal.'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final data = post.data();

                    final name = (data['animalName'] as String?)?.trim();

                    final imageUrl = (data['imageUrl'] as String?) ?? '';

                    final type = (data['postType'] as String?) ?? 'Stray';

                    final location =
                        (data['location'] as String?) ?? 'Unknown location';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      color: _cream,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFFE2B780)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 92,
                                    height: 92,
                                    child: imageUrl.isEmpty
                                        ? const ColoredBox(
                                            color: Color(0xFFF8E2BC),
                                            child: Icon(
                                              Icons.pets,
                                              color: _orange,
                                            ),
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, error, stack) =>
                                                const Icon(
                                                  Icons.pets,
                                                  color: _orange,
                                                ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name == null || name.isEmpty
                                            ? 'Unnamed pet'
                                            : name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: _dark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        type,
                                        style: const TextStyle(color: _orange),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        location,
                                        style: const TextStyle(
                                          color: Color(0xFF80654F),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFFE2B780)),
                            Wrap(
                              spacing: 4,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AnimalDetailsScreen(
                                          postId: post.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('View'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _dark,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _editPost(context, post.id),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _orange,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _deletePost(context, post.id),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animals/create_post_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================

class PawlyColors {
  PawlyColors._();

  // Original PAWLY palette (unchanged)
  static const cream = Color(0xFFFDF8ED);
  static const creamDeep = Color(0xFFFAF3DD);
  static const surface = Color(0xFFFFF8E8);
  static const amber = Color(0xFFF7DCA2);
  static const navBar = Color(0xFFFBE8BC);
  static const navPill = Color(0xFFF4D28E);
  static const espresso = Color(0xFF251605);
  static const burntOrange = Color(0xFFBF5700);
  static const orangeLight = Color(0xFFFF8A2B);
  static const muted = Color(0xFF8A7A66);

  // New complementary shades used by the redesigned feed
  static const ivory = Color(0xFFFFFBF2);
  static const coral = Color(0xFFE9806A);
}

class PawlyText {
  PawlyText._();

  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = PawlyColors.espresso,
    double? height,
  }) => GoogleFonts.lora(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = PawlyColors.espresso,
    double? letterSpacing,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

/// Pastel look for each post category (Stray / Lost / Adoption).
class _CategoryStyle {
  const _CategoryStyle(this.bg, this.fg);

  final Color bg;
  final Color fg;

  static _CategoryStyle? of(String? type) {
    switch (type?.trim()) {
      case 'Stray':
        return const _CategoryStyle(Color(0xFFE4EDD8), Color(0xFF47613A));
      case 'Lost':
        return const _CategoryStyle(Color(0xFFFAD9CE), Color(0xFF9A3F2A));
      case 'Adoption':
        return const _CategoryStyle(Color(0xFFF6E0B5), Color(0xFF86570F));
      default:
        return null;
    }
  }
}

/// Small helper so every animation can respect the phone's
/// "Remove animations" accessibility setting.
bool _reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

// =============================================================================
// HOME FEED SCREEN
// =============================================================================

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key, this.onViewMap});

  final VoidCallback? onViewMap;

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _FilterOption {
  const _FilterOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  static const _filters = [
    _FilterOption('All', Icons.tune_rounded),
    _FilterOption('Stray', Icons.pets_rounded),
    _FilterOption('Lost', Icons.search_rounded),
    _FilterOption('Adoption', Icons.favorite_border_rounded),
  ];

  final _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';
  int _tabIndex = 0;

  final Set<String> _favorites = {};

  late Stream<QuerySnapshot> _postsStream = _buildPostsStream();

  // Firestore query is intentionally unchanged (keeps your composite index).
  Stream<QuerySnapshot> _buildPostsStream() {
    Query query = FirebaseFirestore.instance.collection('posts');

    if (_selectedFilter != 'All') {
      query = query.where('postType', isEqualTo: _selectedFilter);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    if (filter == _selectedFilter) return;
    setState(() {
      _selectedFilter = filter;
      _postsStream = _buildPostsStream();
    });
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (!_favorites.remove(id)) _favorites.add(id);
    });
  }

  void _openMap() {
    if (widget.onViewMap != null) {
      widget.onViewMap!();
      return;
    }
    setState(() => _tabIndex = 2);
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.of(context)
          .push<int>(
            MaterialPageRoute<int>(builder: (_) => const CreatePostScreen()),
          )
          .then((selectedIndex) {
            if (!mounted || selectedIndex == null) return;

            setState(() {
              _tabIndex = selectedIndex;
            });
          });
      return;
    }

    setState(() {
      _tabIndex = index;
    });
  }

  void _openPost(String id, Map<String, dynamic> data) {}

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      data['animalName'],
      data['breed'],
      data['location'],
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    if (_tabIndex == 0) {
      currentBody = _buildFeed();
    } else if (_tabIndex == 2) {
      currentBody = MapScreen(); // Map Screen (Index 2)
    } else if (_tabIndex == 3) {
      currentBody = const _PlaceholderTab(
        icon: Icons.favorite_rounded,
        title: 'Saved paws',
        message: 'Animals you save will show up here.',
      );
    } else if (_tabIndex == 4) {
      currentBody = ProfileScreen(); // Profile Screen (Index 4)
    } else {
      currentBody = _buildFeed();
    }

    return Scaffold(
      backgroundColor: PawlyColors.cream,
      extendBody: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PawlyColors.amber, Color(0xFFFCEFD0), PawlyColors.cream],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(bottom: false, child: currentBody),
      ),
      bottomNavigationBar: PawlyBottomNav(
        currentIndex: _tabIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FEED
  // ---------------------------------------------------------------------------

  Widget _buildFeed() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildFilterChips()),
        SliverToBoxAdapter(child: _buildSectionHeader()),
        StreamBuilder<QuerySnapshot>(
          stream: _postsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _StatusMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn’t load the feed',
                  message: 'Check your connection and try again.',
                  detail: '${snapshot.error}',
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: _PawLoader()),
              );
            }

            final docs = (snapshot.data?.docs ?? [])
                .where((d) => _matchesSearch(d.data() as Map<String, dynamic>))
                .toList();

            if (docs.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyFeed(searching: _searchQuery.trim().isNotEmpty),
              );
            }

            final reduceMotion = _reduceMotion(context);

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              sliver: SliverList.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final delay = (index < 4 ? index * 80 : 0).ms;

                  final card = _PostCard(
                    data: data,
                    isFavorite: _favorites.contains(doc.id),
                    onFavorite: () => _toggleFavorite(doc.id),
                    onOpen: () => _openPost(doc.id, data),
                  );

                  if (reduceMotion) return card;

                  return card
                      .animate(key: ValueKey(doc.id))
                      .fadeIn(
                        duration: 420.ms,
                        delay: delay,
                        curve: Curves.easeOut,
                      )
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 520.ms,
                        delay: delay,
                        curve: Curves.easeOutCubic,
                      );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Guest User';

    // "Thulakshie Attanayake" -> "Thulakshie"
    final trimmed = displayName.trim();
    final firstWord = trimmed.isEmpty ? '' : trimmed.split(RegExp(r'\s+')).first;
    final firstName = firstWord.isEmpty
        ? 'friend'
        : firstWord[0].toUpperCase() + firstWord.substring(1);

    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Hi, $firstName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PawlyText.serif(size: 30, height: 1.1),
              ),
            ),
            const SizedBox(width: 8),
            const _WavingPaw(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to help a paw today?',
          style: PawlyText.sans(
            size: 14.5,
            weight: FontWeight.w500,
            color: PawlyColors.espresso.withValues(alpha: 0.66),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo, username (opens Profile), notification bell
          Row(
            children: [
              const Icon(
                Icons.pets_rounded,
                color: PawlyColors.espresso,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                'PAWLY',
                style: PawlyText.sans(
                  size: 24,
                  weight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildUsernameButton(displayName),
                ),
              ),
              const SizedBox(width: 8),
              _buildBell(),
            ],
          ),
          const SizedBox(height: 18),

          // Greeting + puppy peeking over the search bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _entrance(context, greeting)),
              const SizedBox(width: 8),
              Transform.translate(
                offset: const Offset(0, 9),
                child: const _PuppyPeek(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _PawlySearchField(
            controller: _searchController,
            query: _searchQuery,
            onChanged: (v) => setState(() => _searchQuery = v),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ],
      ),
    );
  }

  Widget _entrance(BuildContext context, Widget child) {
    if (_reduceMotion(context)) return child;
    return child
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildUsernameButton(String displayName) {
    return Material(
      color: PawlyColors.ivory.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onNavTap(4), // Opens the Profile tab
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_rounded,
                  size: 18,
                  color: PawlyColors.burntOrange,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PawlyText.sans(size: 13.5, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: PawlyColors.surface,
          shape: const CircleBorder(),
          elevation: 1.5,
          shadowColor: PawlyColors.burntOrange.withValues(alpha: 0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.notifications_none_rounded,
                color: PawlyColors.espresso,
                size: 22,
              ),
            ),
          ),
        ),
        Positioned(
          right: 9,
          top: 9,
          child: IgnorePointer(
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: PawlyColors.burntOrange,
                shape: BoxShape.circle,
                border: Border.all(color: PawlyColors.surface, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final option = _filters[i];
          return Center(
            child: _FilterChipButton(
              label: option.label,
              icon: option.icon,
              selected: option.label == _selectedFilter,
              onTap: () => _onFilterSelected(option.label),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Little paws, nearby',
              style: PawlyText.serif(size: 19),
            ),
          ),
          TextButton.icon(
            onPressed: _openMap,
            style: TextButton.styleFrom(
              foregroundColor: PawlyColors.burntOrange,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.map_outlined, size: 17),
            label: Text(
              'View map',
              style: PawlyText.sans(
                size: 13.5,
                weight: FontWeight.w800,
                color: PawlyColors.burntOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SEARCH FIELD (focus-aware)
// =============================================================================

class _PawlySearchField extends StatefulWidget {
  const _PawlySearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_PawlySearchField> createState() => _PawlySearchFieldState();
}

class _PawlySearchFieldState extends State<_PawlySearchField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 240);

    return AnimatedContainer(
      duration: dur,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: PawlyColors.ivory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _focused
              ? PawlyColors.burntOrange.withValues(alpha: 0.55)
              : PawlyColors.burntOrange.withValues(alpha: 0.10),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PawlyColors.burntOrange.withValues(
              alpha: _focused ? 0.18 : 0.06,
            ),
            blurRadius: _focused ? 22 : 14,
            offset: Offset(0, _focused ? 8 : 5),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: PawlyColors.burntOrange,
        style: PawlyText.sans(size: 15),
        decoration: InputDecoration(
          hintText: 'Search a name, breed or neighborhood',
          hintStyle: PawlyText.sans(
            size: 14,
            weight: FontWeight.w500,
            color: PawlyColors.muted,
          ),
          prefixIcon: AnimatedScale(
            scale: _focused ? 1.14 : 1.0,
            duration: dur,
            curve: Curves.easeOutBack,
            child: Icon(
              Icons.search_rounded,
              color: _focused ? PawlyColors.burntOrange : PawlyColors.muted,
            ),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: dur,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: widget.query.isEmpty
                ? const SizedBox(key: ValueKey('empty'), width: 48)
                : IconButton(
                    key: const ValueKey('clear'),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PawlyColors.muted,
                      size: 20,
                    ),
                    onPressed: widget.onClear,
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// =============================================================================
// FILTER CHIPS
// =============================================================================

class _FilterChipButton extends StatefulWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fg = selected ? Colors.white : PawlyColors.espresso;
    final iconColor = selected ? Colors.white : PawlyColors.burntOrange;
    final reduce = _reduceMotion(context);
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 300);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : (selected ? 1.04 : 1.0),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: dur,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? PawlyColors.burntOrange : PawlyColors.ivory,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? PawlyColors.burntOrange
                  : PawlyColors.burntOrange.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: PawlyColors.burntOrange.withValues(
                  alpha: selected ? 0.28 : 0.0,
                ),
                blurRadius: selected ? 12 : 0,
                offset: Offset(0, selected ? 5 : 0),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: iconColor),
                duration: dur,
                builder: (context, color, _) =>
                    Icon(widget.icon, size: 17, color: color),
              ),
              const SizedBox(width: 7),
              AnimatedDefaultTextStyle(
                duration: dur,
                curve: Curves.easeOutCubic,
                style: PawlyText.sans(
                  size: 14,
                  weight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: fg,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// POST CARD — "Gallery Print"
// =============================================================================

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.data,
    required this.isFavorite,
    required this.onFavorite,
    required this.onOpen,
  });

  final Map<String, dynamic> data;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  int _heartBurst = 0; // big heart over the photo (double-tap)
  int _sparkleBurst = 0; // little sparkles by the heart button (on save)
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sparkle whenever the post goes from "not saved" to "saved".
    if (!oldWidget.isFavorite && widget.isFavorite) {
      _sparkleBurst++;
    }
  }

  // Double-tap to like and play the heart animation.
  void _onDoubleTap() {
    // If already liked, do not unlike it.
    if (!widget.isFavorite) {
      widget.onFavorite();
    }

    // Trigger the animation every time.
    setState(() {
      _heartBurst++;
    });
  }

  String? _timeAgo(dynamic value) {
    if (value is! Timestamp) return null;
    final date = value.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final rawName = (widget.data['animalName'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : 'Unnamed Pet';
    final imageUrl = (widget.data['imageUrl'] as String?)?.trim();
    final location = (widget.data['location'] as String?)?.trim() ?? '';
    final category = (widget.data['postType'] as String?)?.trim();
    final categoryStyle = _CategoryStyle.of(category);
    final timeAgo = _timeAgo(widget.data['createdAt']);
    final reduce = _reduceMotion(context);

    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Semantics(
      label: [
        name,
        if (category != null && category.isNotEmpty) category,
        if (location.isNotEmpty) location,
      ].join(', '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onOpen,
        onDoubleTap: _onDoubleTap,
        child: AnimatedScale(
          scale: (_pressed && !reduce) ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: PawlyColors.espresso.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Photo (with soft placeholder + fade-in)
                    ColoredBox(
                      color: PawlyColors.amber.withValues(alpha: 0.45),
                      child: const Center(
                        child: Icon(
                          Icons.pets_rounded,
                          size: 44,
                          color: PawlyColors.burntOrange,
                        ),
                      ),
                    ),
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.35),
                        cacheWidth: cacheWidth,
                        frameBuilder: (context, child, frame, wasSync) {
                          if (wasSync) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                        // On error the placeholder behind stays visible.
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),

                    // 2. Soft bottom scrim so the info strip separates
                    //    from bright photos
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 150,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00251605), Color(0x47251605)],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Category "collar tag" (top-left)
                    if (categoryStyle != null && category != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _CategoryTag(label: category, style: categoryStyle),
                      ),

                    // 4. Floating info strip (bottom)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _InfoStrip(
                        name: name,
                        location: location,
                        timeAgo: timeAgo,
                      ),
                    ),

                    // 5. Sparkles when saved
                    if (_sparkleBurst > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: _Sparkles(burst: _sparkleBurst),
                      ),

                    // 6. Favorite button (top-right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _HeartButton(
                        isFavorite: widget.isFavorite,
                        onTap: widget.onFavorite,
                      ),
                    ),

                    // 7. Big heart pop on double-tap
                    if (_heartBurst > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: _HeartPop(burst: _heartBurst, reduce: reduce),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Category pill with a tiny "collar ring" — PAWLY's signature detail.
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.style});

  final String label;
  final _CategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: style.fg.withValues(alpha: 0.75),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: PawlyText.sans(
              size: 12,
              weight: FontWeight.w800,
              color: style.fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.name,
    required this.location,
    required this.timeAgo,
  });

  final String name;
  final String location;
  final String? timeAgo;

  @override
  Widget build(BuildContext context) {
    final hasLocation = location.isNotEmpty;
    final hasTime = timeAgo != null && timeAgo!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: PawlyColors.ivory.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: PawlyColors.espresso.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PawlyText.serif(size: 19, height: 1.15),
          ),
          if (hasLocation || hasTime) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (hasLocation) ...[
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: PawlyColors.burntOrange,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PawlyText.sans(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: PawlyColors.muted,
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: PawlyColors.burntOrange,
                  ),
                  const SizedBox(width: 3),
                ],
                if (hasTime) ...[
                  if (hasLocation)
                    Text(
                      '  ·  ',
                      style: PawlyText.sans(
                        size: 12.5,
                        color: PawlyColors.muted,
                      ),
                    ),
                  Text(
                    timeAgo!,
                    maxLines: 1,
                    style: PawlyText.sans(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: PawlyColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);

    return Semantics(
      button: true,
      label: isFavorite ? 'Remove from saved' : 'Save animal',
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Material(
            color: PawlyColors.ivory.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 38,
                height: 38,
                child: AnimatedSwitcher(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  switchInCurve: Curves.elasticOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isFavorite),
                    size: 21,
                    color: isFavorite
                        ? PawlyColors.burntOrange
                        : PawlyColors.espresso.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big heart that springs in over the photo, then floats up and fades.
class _HeartPop extends StatelessWidget {
  const _HeartPop({required this.burst, required this.reduce});

  final int burst;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final heart = Stack(
      alignment: Alignment.center,
      children: const [
        // White halo behind, so the heart reads on any photo
        Icon(Icons.favorite_rounded, size: 124, color: Colors.white),
        Icon(
          Icons.favorite_rounded,
          size: 106,
          color: PawlyColors.burntOrange,
        ),
      ],
    );

    if (reduce) {
      return heart
          .animate(key: ValueKey(burst))
          .fadeIn(duration: 150.ms)
          .fadeOut(delay: 550.ms, duration: 250.ms);
    }

    return heart
        .animate(key: ValueKey(burst))
        .fadeIn(duration: 100.ms)
        .scaleXY(
          begin: 0.2,
          end: 1.0,
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .moveY(
          begin: 0,
          end: -16,
          delay: 420.ms,
          duration: 380.ms,
          curve: Curves.easeIn,
        )
        .fadeOut(delay: 520.ms, duration: 280.ms);
  }
}

/// Six tiny stars that burst outward from the heart button when saved.
class _Sparkles extends StatelessWidget {
  const _Sparkles({required this.burst});

  final int burst;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return const SizedBox.shrink();

    const count = 6;
    const distance = 26.0;

    return IgnorePointer(
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              Icon(
                Icons.star_rounded,
                size: i.isEven ? 11.0 : 8.0,
                color: i.isEven
                    ? PawlyColors.burntOrange
                    : const Color(0xFFE9A53B),
              )
                  .animate(key: ValueKey('spark-$burst-$i'))
                  .scaleXY(
                    begin: 0.3,
                    end: 1.0,
                    duration: 260.ms,
                    curve: Curves.easeOutBack,
                  )
                  .move(
                    begin: Offset.zero,
                    end: Offset(
                      math.cos(i * 2 * math.pi / count) * distance,
                      math.sin(i * 2 * math.pi / count) * distance,
                    ),
                    duration: 520.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeOut(delay: 280.ms, duration: 260.ms),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER ILLUSTRATIONS (drawn in code — no asset files needed)
// =============================================================================

/// A small paw that waves once after the greeting appears.
class _WavingPaw extends StatefulWidget {
  const _WavingPaw();

  @override
  State<_WavingPaw> createState() => _WavingPawState();
}

class _WavingPawState extends State<_WavingPaw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || _reduceMotion(context)) return;
    _started = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final angle = math.sin(t * math.pi * 5) * 0.4 * (1 - t);
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      

child: ColorFiltered(
  colorFilter: const ColorFilter.mode(
    PawlyColors.burntOrange,
    BlendMode.srcIn,
  ),
  child: const Text(
    '🐾',
    style: TextStyle(fontSize: 24),
  ),
),


    );
  }
}

/// A puppy that peeks over the top edge of the search bar and
/// tilts its head every few seconds.
class _PuppyPeek extends StatefulWidget {
  const _PuppyPeek();

  @override
  State<_PuppyPeek> createState() => _PuppyPeekState();
}

class _PuppyPeekState extends State<_PuppyPeek>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          var angle = 0.0;
          // Head tilt happens between 55% and 85% of each 6s loop.
          if (t > 0.55 && t < 0.85) {
            angle = math.sin((t - 0.55) / 0.30 * math.pi) * 0.17;
          }
          return Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: const RepaintBoundary(
          child: CustomPaint(size: Size(72, 54), painter: _PuppyPainter()),
        ),
      ),
    );
  }
}

class _PuppyPainter extends CustomPainter {
  const _PuppyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 72, size.height / 54);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Floppy ears
    fill.color = const Color(0xFFB27635);
    canvas.save();
    canvas.translate(17, 24);
    canvas.rotate(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 22),
      fill,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(55, 24);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 22),
      fill,
    );
    canvas.restore();

    // Head
    fill.color = const Color(0xFFE2AE68);
    canvas.drawCircle(const Offset(36, 31), 20, fill);

    // Muzzle
    fill.color = const Color(0xFFFFF3DC);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 38.5), width: 18, height: 12),
      fill,
    );

    // Cheeks
    fill.color = const Color(0x40E9806A);
    canvas.drawCircle(const Offset(23.5, 36), 3.4, fill);
    canvas.drawCircle(const Offset(48.5, 36), 3.4, fill);

    // Eyes + highlights
    fill.color = PawlyColors.espresso;
    canvas.drawCircle(const Offset(28.5, 30), 2.4, fill);
    canvas.drawCircle(const Offset(43.5, 30), 2.4, fill);
    fill.color = Colors.white;
    canvas.drawCircle(const Offset(29.2, 29.2), 0.8, fill);
    canvas.drawCircle(const Offset(44.2, 29.2), 0.8, fill);

    // Nose
    fill.color = PawlyColors.espresso;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 35.2), width: 6.4, height: 4.4),
      fill,
    );

    // Mouth
    stroke
      ..color = PawlyColors.espresso
      ..strokeWidth = 1.2;
    final mouth = Path()
      ..moveTo(36, 37.4)
      ..lineTo(36, 39.4)
      ..moveTo(36, 39.4)
      ..quadraticBezierTo(33.8, 41.6, 31.8, 39.8)
      ..moveTo(36, 39.4)
      ..quadraticBezierTo(38.2, 41.6, 40.2, 39.8);
    canvas.drawPath(mouth, stroke);

    // Paws gripping the edge
    fill.color = const Color(0xFFFFF3DC);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 51.5), width: 13, height: 8),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(48, 51.5), width: 13, height: 8),
      fill,
    );
    stroke
      ..color = const Color(0x66B27635)
      ..strokeWidth = 0.8;
    for (final x in const [24.0, 48.0]) {
      canvas.drawLine(Offset(x - 2, 49.5), Offset(x - 2, 52), stroke);
      canvas.drawLine(Offset(x + 2, 49.5), Offset(x + 2, 52), stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KittenPainter extends CustomPainter {
  const _KittenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140, size.height / 90);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ground shadow
    fill.color = const Color(0x14251605);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(70, 82), width: 112, height: 10),
      fill,
    );

    // Tail curled around the body
    stroke
      ..color = const Color(0xFFD9A55F)
      ..strokeWidth = 9;
    final tail = Path()
      ..moveTo(30, 72)
      ..quadraticBezierTo(6, 74, 11, 54)
      ..quadraticBezierTo(13, 45, 23, 47);
    canvas.drawPath(tail, stroke);

    // Body
    fill.color = const Color(0xFFE9C38E);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(66, 62), width: 96, height: 46),
      fill,
    );

    // Stripes
    stroke
      ..color = const Color(0xFFD9A55F)
      ..strokeWidth = 3;
    for (final x in const [44.0, 58.0, 72.0]) {
      canvas.drawLine(Offset(x, 42), Offset(x - 2, 50), stroke);
    }

    // Ears (behind head)
    fill.color = const Color(0xFFEFCB9A);
    canvas.drawPath(
      Path()
        ..moveTo(84, 46)
        ..lineTo(86, 26)
        ..lineTo(99, 38)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(103, 38)
        ..lineTo(116, 26)
        ..lineTo(118, 46)
        ..close(),
      fill,
    );
    fill.color = const Color(0xFFF4B8A8);
    canvas.drawPath(
      Path()
        ..moveTo(88, 40)
        ..lineTo(88.5, 31)
        ..lineTo(95, 37)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(107, 37)
        ..lineTo(113.5, 31)
        ..lineTo(114, 40)
        ..close(),
      fill,
    );

    // Head
    fill.color = const Color(0xFFEFCB9A);
    canvas.drawCircle(const Offset(101, 58), 21, fill);

    // Front paw tucked under chin
    fill.color = const Color(0xFFFFF3DC);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(86, 77), width: 18, height: 9),
      fill,
    );

    // Closed, sleepy eyes
    stroke
      ..color = PawlyColors.espresso
      ..strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(94, 57), width: 9, height: 6),
      0,
      math.pi,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(108, 57), width: 9, height: 6),
      0,
      math.pi,
      false,
      stroke,
    );

    // Nose + whiskers
    fill.color = PawlyColors.coral;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(101, 63), width: 4.4, height: 3.2),
      fill,
    );
    stroke
      ..color = const Color(0x80251605)
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(90, 64), const Offset(80, 62), stroke);
    canvas.drawLine(const Offset(90, 67), const Offset(80, 68), stroke);
    canvas.drawLine(const Offset(112, 64), const Offset(122, 62), stroke);
    canvas.drawLine(const Offset(112, 67), const Offset(122, 68), stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// LOADING + EMPTY + ERROR STATES
// =============================================================================

/// Four little paw prints that "walk" by lighting up one after another.
class _PawLoader extends StatefulWidget {
  const _PawLoader();

  @override
  State<_PawLoader> createState() => _PawLoaderState();
}

class _PawLoaderState extends State<_PawLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 0 : 10,
                      top: i.isOdd ? 14 : 0,
                    ),
                    child: Transform.rotate(
                      angle: i.isOdd ? 0.35 : -0.35,
                      child: Opacity(
                        opacity: reduce ? 0.6 : _pawOpacity(i),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 26,
                          color: PawlyColors.burntOrange,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Finding little paws…',
          style: PawlyText.sans(
            size: 13.5,
            weight: FontWeight.w500,
            color: PawlyColors.muted,
          ),
        ),
      ],
    );
  }

  double _pawOpacity(int index) {
    final x = (_controller.value - index * 0.2) % 1.0;
    return 0.2 + 0.8 * (1 - (x * 1.5).clamp(0.0, 1.0));
  }
}

/// Shown when there are no animals (or no search matches):
/// a sleeping kitten with floating "z"s.
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);

    Widget kitten = const CustomPaint(
      size: Size(150, 96),
      painter: _KittenPainter(),
    );

    if (!reduce) {
      kitten = kitten
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.03,
            alignment: Alignment.bottomCenter,
            duration: 1800.ms,
            curve: Curves.easeInOut,
          );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  kitten,
                  Positioned(right: 14, top: 4, child: _sleepyZ(0, 20, reduce)),
                  Positioned(right: 0, top: 16, child: _sleepyZ(900, 15, reduce)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              searching ? 'No paws match your search' : 'No animals here yet',
              style: PawlyText.serif(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a different name, breed or neighborhood.'
                  : 'Spotted an animal that needs help? Tap Post to add the first one.',
              textAlign: TextAlign.center,
              style: PawlyText.sans(size: 14, color: PawlyColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleepyZ(int delayMs, double size, bool reduce) {
    final z = Text(
      'z',
      style: PawlyText.serif(
        size: size,
        color: PawlyColors.burntOrange.withValues(alpha: 0.75),
      ).copyWith(fontStyle: FontStyle.italic),
    );
    if (reduce) return z;
    return z
        .animate(
          delay: delayMs.ms,
          onPlay: (c) => c.repeat(),
        )
        .fadeIn(duration: 500.ms)
        .moveY(begin: 0, end: -14, duration: 1800.ms, curve: Curves.easeOut)
        .fadeOut(delay: 1300.ms, duration: 500.ms);
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: PawlyColors.burntOrange),
            const SizedBox(height: 16),
            Text(
              title,
              style: PawlyText.serif(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PawlyText.sans(size: 14, color: PawlyColors.muted),
            ),
            if (detail != null) ...[
              const SizedBox(height: 12),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: PawlyText.sans(size: 12, color: Colors.red.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: PawlyColors.burntOrange),
            const SizedBox(height: 16),
            Text(title, style: PawlyText.serif(size: 22)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PawlyText.sans(size: 14, color: PawlyColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM NAVIGATION (unchanged — also used by CreatePostScreen)
// =============================================================================

class PawlyBottomNav extends StatelessWidget {
  const PawlyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PawlyColors.navBar,
        border: Border(
          top: BorderSide(
            color: PawlyColors.burntOrange.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.add_circle_outline_rounded, 'Post'),
              _navItem(2, Icons.map_rounded, 'Map'), // Map Tab (Index 2)
              _navItem(3, Icons.favorite_rounded, 'Saved'),
              _navItem(
                4,
                Icons.person_rounded,
                'Profile',
              ), // Profile Tab (Index 4)
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = currentIndex == index;
    final color = selected
        ? PawlyColors.burntOrange
        : PawlyColors.espresso.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: PawlyText.sans(
                size: 11,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

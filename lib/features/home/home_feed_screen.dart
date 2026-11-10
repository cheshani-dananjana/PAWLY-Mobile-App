import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animals/create_post_screen.dart';

class PawlyColors {
  PawlyColors._();

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
}

class PawlyText {
  PawlyText._();

  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = PawlyColors.espresso,
    double? height,
  }) =>
      GoogleFonts.lora(
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
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({
    super.key,
    this.onViewMap,
  });

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

  late Stream<QuerySnapshot>_postsStream = _buildPostsStream();

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map view is coming soon.')),
    );
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      return;
    }
    setState(() => _tabIndex = index);
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
    return Scaffold(
      backgroundColor: PawlyColors.cream,
      extendBody: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PawlyColors.amber,
              Color(0xFFFCEFD0),
              PawlyColors.cream,
            ],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _tabIndex == 0
              ? _buildFeed()
              : _PlaceholderTab(
                  icon: _tabIndex == 2 ? Icons.favorite_rounded : Icons.person_rounded,
                  title: _tabIndex == 2 ? 'Saved paws' : 'Your profile',
                  message: _tabIndex == 2
                      ? 'Animals you save will show up here.'
                      : 'Profile settings are on the way.',
                ),
        ),
      ),
      bottomNavigationBar: _PawlyBottomNav(
        currentIndex: _tabIndex,
        onTap: _onNavTap,
      ),
    );
  }

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

            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: PawlyColors.burntOrange,
                  ),
                ),
              );
            }

            final docs = (snapshot.data?.docs ?? [])
                .where((d) => _matchesSearch(d.data() as Map<String, dynamic>))
                .toList();

            if (docs.isEmpty) {
              final searching = _searchQuery.trim().isNotEmpty;
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _StatusMessage(
                  icon: Icons.pets_rounded,
                  title: searching ? 'No paws match your search' : 'No animals here yet',
                  message: searching
                      ? 'Try a different name, breed or neighborhood.'
                      : 'Spotted an animal that needs help? Tap Post to add the first one.',
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              sliver: SliverList.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final delay = (index < 5 ? index * 90 : 0).ms;

                  return _PostCard(
                    data: data,
                    isFavorite: _favorites.contains(doc.id),
                    onFavorite: () => _toggleFavorite(doc.id),
                    onOpen: () => _openPost(doc.id, data),
                  )
                      .animate(key: ValueKey(doc.id))
                      .fadeIn(
                        duration: 380.ms,
                        delay: delay,
                        curve: Curves.easeOut,
                      )
                      .slideY(
                        begin: 0.16,
                        end: 0,
                        duration: 650.ms,
                        delay: delay,
                        curve: Curves.easeOutBack,
                      )
                      .scale(
                        begin: const Offset(0.94, 0.94),
                        end: const Offset(1, 1),
                        alignment: Alignment.bottomCenter,
                        duration: 650.ms,
                        delay: delay,
                        curve: Curves.easeOutBack,
                      );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Guest User';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets_rounded, color: PawlyColors.espresso, size: 26),
              const SizedBox(width: 8),
              Text(
                'PAWLY',
                style: PawlyText.sans(
                  size: 24,
                  weight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              const Icon(Icons.account_circle_rounded, size: 18, color: PawlyColors.burntOrange),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: PawlyText.sans(size: 14, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              _buildBell(),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Small acts.\nSecond chances.',
            style: PawlyText.serif(size: 34, height: 1.12),
          )
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 700.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 20),
          _buildSearchBar(),
        ],
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
          shadowColor: PawlyColors.burntOrange.withOpacity(0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.notifications_none_rounded, color: PawlyColors.espresso, size: 22),
            ),
          ),
        ),
        Positioned(
          right: 9,
          top: 9,
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
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: PawlyColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PawlyColors.burntOrange.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: PawlyColors.burntOrange.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
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
          prefixIcon: const Icon(Icons.search_rounded, color: PawlyColors.burntOrange),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: PawlyColors.muted, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 64,
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
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : (selected ? 1.06 : 1.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? PawlyColors.burntOrange : PawlyColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? PawlyColors.burntOrange
                  : PawlyColors.burntOrange.withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: PawlyColors.burntOrange.withOpacity(selected ? 0.35 : 0.0),
                blurRadius: selected ? 16 : 0,
                offset: Offset(0, selected ? 6 : 0),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: iconColor),
                duration: const Duration(milliseconds: 300),
                builder: (context, color, _) => Icon(widget.icon, size: 17, color: color),
              ),
              const SizedBox(width: 7),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
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

class _TypeStyle {
  const _TypeStyle(this.icon, this.background, this.foreground);
  final IconData icon;
  final Color background;
  final Color foreground;

  static _TypeStyle of(String type) {
    switch (type.toLowerCase()) {
      case 'adoption':
        return const _TypeStyle(
          Icons.favorite_border_rounded,
          Color(0xFFE6F0D6),
          Color(0xFF3E6B2B),
        );
      case 'lost':
        return const _TypeStyle(
          Icons.search_rounded,
          Color(0xFFFFDCC6),
          PawlyColors.burntOrange,
        );
      case 'stray':
        return const _TypeStyle(
          Icons.pets_rounded,
          Color(0xFFFFEBC2),
          Color(0xFF8A5200),
        );
      default:
        return const _TypeStyle(
          Icons.pets_rounded,
          PawlyColors.surface,
          PawlyColors.espresso,
        );
    }
  }
}

class _PostCard extends StatelessWidget {
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

  static const _fallbackImage = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1';

  String? _ageLabel(dynamic age) {
    if (age == null) return null;
    if (age is num) {
      final n = age % 1 == 0 ? age.toInt().toString() : age.toString();
      return '$n ${age == 1 ? 'year' : 'years'}';
    }
    final s = age.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? _distanceLabel(dynamic distance) {
    if (distance == null) return null;
    if (distance is num) return '${distance.toStringAsFixed(1)} mi';
    final s = distance.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['animalName'] as String?)?.trim();
    final type = (data['postType'] as String?)?.trim() ?? '';
    final imageUrl = (data['imageUrl'] as String?)?.trim();

    final subtitle = [_ageLabel(data['age']), (data['breed'] as String?)?.trim()]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(' · ');

    final location = [
      (data['location'] as String?)?.trim(),
      _distanceLabel(data['distance']),
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PawlyColors.espresso.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: PawlyColors.burntOrange.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: PawlyColors.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          splashColor: PawlyColors.burntOrange.withOpacity(0.08),
          highlightColor: PawlyColors.burntOrange.withOpacity(0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: PawlyColors.creamDeep,
                          alignment: Alignment.center,
                          child: const Icon(Icons.pets_rounded, color: PawlyColors.muted, size: 32),
                        ),
                        Image.network(
                          (imageUrl == null || imageUrl.isEmpty) ? _fallbackImage : imageUrl,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: PawlyColors.creamDeep,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined, color: PawlyColors.muted, size: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (type.isNotEmpty)
                    Positioned(top: 14, left: 14, child: _TypePill(type: type)),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _HeartButton(
                      isFavorite: isFavorite,
                      onTap: onFavorite,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            (name == null || name.isEmpty) ? 'Unknown' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PawlyText.serif(size: 24),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: PawlyText.sans(
                                size: 13,
                                weight: FontWeight.w600,
                                color: PawlyColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: PawlyColors.burntOrange),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location.isEmpty ? 'Location not shared' : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PawlyText.sans(
                              size: 13.5,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: PawlyColors.burntOrange.withOpacity(0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onOpen,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.north_east_rounded, size: 18, color: PawlyColors.burntOrange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final style = _TypeStyle.of(type);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 13, 6),
      decoration: BoxDecoration(
        color: style.background.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: style.foreground.withOpacity(0.28),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 15, color: style.foreground),
          const SizedBox(width: 5),
          Text(
            type,
            style: PawlyText.sans(
              size: 12.5,
              weight: FontWeight.w800,
              color: style.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartButton extends StatefulWidget {
  const _HeartButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.7).chain(CurveTween(curve: Curves.easeIn)),
      weight: 16,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.7, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 84,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_controller.value);
          final showRing = widget.isFavorite && _controller.value > 0 && _controller.value < 1;

          return SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (showRing)
                  Transform.scale(
                    scale: 1 + t * 0.9,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5484D).withOpacity((1 - t) * 0.55),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                Transform.scale(scale: _scale.value, child: child),
              ],
            ),
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 21,
            color: widget.isFavorite ? const Color(0xFFE5484D) : PawlyColors.espresso,
          ),
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: PawlyColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PawlyColors.burntOrange.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: PawlyColors.burntOrange),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PawlyText.serif(size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PawlyText.sans(
              size: 15,
              weight: FontWeight.w500,
              color: PawlyColors.muted,
            ).copyWith(height: 1.4),
          ),
          if (detail != null) ...[
            const SizedBox(height: 12),
            Text(
              detail!,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: PawlyText.sans(
                size: 11,
                weight: FontWeight.w500,
                color: PawlyColors.muted.withOpacity(0.7),
              ),
            ),
          ],
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutBack,
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
      child: _StatusMessage(icon: icon, title: title, message: message),
    );
  }
}

class _PawlyBottomNav extends StatelessWidget {
  const _PawlyBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PawlyColors.navBar,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: PawlyColors.espresso.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.add_circle_outline_rounded,
                  activeIcon: Icons.add_circle_rounded,
                  label: 'Post',
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: 'Saved',
                  active: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  active: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active ? PawlyColors.navPill : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedScale(
              scale: active ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: Icon(
                active ? activeIcon : icon,
                size: 24,
                color: active ? PawlyColors.burntOrange : PawlyColors.espresso,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: PawlyText.sans(
              size: 12,
              weight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? PawlyColors.espresso : PawlyColors.muted,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
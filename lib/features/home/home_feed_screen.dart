import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animals/create_post_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

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
          MaterialPageRoute<int>(
            builder: (_) => const CreatePostScreen(),
          ),
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
                  title: searching
                      ? 'No paws match your search'
                      : 'No animals here yet',
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
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Guest User';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
             
const Spacer(),
InkWell(
  borderRadius: BorderRadius.circular(12),
  onTap: () => _onNavTap(4),
  child: Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 8,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_circle_rounded,
          size: 18,
          color: PawlyColors.burntOrange,
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            displayName,
            overflow: TextOverflow.ellipsis,
            style: PawlyText.sans(
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: PawlyColors.burntOrange,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: PawlyColors.muted,
                    size: 20,
                  ),
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
                color: PawlyColors.burntOrange.withOpacity(
                  selected ? 0.35 : 0.0,
                ),
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
                builder: (context, color, _) =>
                    Icon(widget.icon, size: 17, color: color),
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

  String? _ageLabel(dynamic age) {
    if (age == null) return null;
    if (age is num) {
      final n = age % 1 == 0 ? age.toInt().toString() : age.toString();
      return '$n${age == 1 ? 'year' : 'years'}';
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
    final imageUrl = (data['imageUrl'] as String?)?.trim();

    final subtitle = [
      _ageLabel(data['age']),
      (data['breed'] as String?)?.trim(),
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: PawlyColors.amber.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.pets,
                          color: PawlyColors.burntOrange,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name != null && name.isNotEmpty
                                ? name
                                : 'Unnamed Pet',
                            style: PawlyText.serif(size: 18),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: PawlyText.sans(
                                size: 13,
                                color: PawlyColors.muted,
                              ),
                            ),
                          ],
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: PawlyColors.burntOrange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: PawlyText.sans(
                                      size: 12,
                                      color: PawlyColors.muted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? PawlyColors.burntOrange
                            : PawlyColors.muted,
                      ),
                      onPressed: onFavorite,
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
            color: PawlyColors.burntOrange.withOpacity(0.15),
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
        : PawlyColors.espresso.withOpacity(0.6);

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

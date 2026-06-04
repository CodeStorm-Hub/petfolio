import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/platform/web_image_cache.dart';
import '../../data/models/story.dart';
import '../controllers/story_controller.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.initialPetId,
  });

  final String initialPetId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late final PageController _pageController;
  int _currentPetIndex = 0;
  int _currentStoryIndex = 0;

  // Stacks of stories grouped by pet
  List<PetStoryStack> _petStacks = [];
  bool _initialized = false;

  // Timer & progress management
  Timer? _timer;
  double _progress = 0.0;
  static const int _storyDurationMs = 5000; // 5 seconds per story
  static const int _tickMs = 50; // Update progress every 50ms
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _setupStacks(List<Story> allStories) {
    if (_initialized) return;

    final grouped = <String, List<Story>>{};
    for (final story in allStories) {
      grouped.putIfAbsent(story.petId, () => []).add(story);
    }

    final stacks = grouped.entries.map((e) {
      final first = e.value.first;
      final sortedStories = List<Story>.from(e.value)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return PetStoryStack(
        petId: e.key,
        petName: first.petName,
        petAvatarUrl: first.petAvatarUrl,
        petSpecies: first.petSpecies,
        stories: sortedStories,
      );
    }).toList();

    int initialIndex = stacks.indexWhere((s) => s.petId == widget.initialPetId);
    if (initialIndex == -1) initialIndex = 0;

    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _petStacks = stacks;
        _currentPetIndex = initialIndex;
        _initialized = true;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(initialIndex);
      }
      _startStory();
    });
  }

  void _startStory({double fromProgress = 0.0}) {
    _timer?.cancel();
    if (_petStacks.isEmpty) return;

    setState(() {
      _progress = fromProgress;
      _isPaused = false;
    });

    if (fromProgress == 0.0) {
      final currentStory = _petStacks[_currentPetIndex].stories[_currentStoryIndex];
      ref.read(storiesProvider.notifier).markStoryViewed(currentStory.id);
    }

    final totalTicks = _storyDurationMs / _tickMs;
    final increment = 1.0 / totalTicks;

    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      if (_isPaused) return;

      setState(() {
        _progress += increment;
      });

      if (_progress >= 1.0) {
        _timer?.cancel();
        _nextStory();
      }
    });
  }

  void _nextStory() {
    final currentStack = _petStacks[_currentPetIndex];
    if (_currentStoryIndex < currentStack.stories.length - 1) {
      // Next story in the same pet's stack
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      // Last story in current stack -> go to next pet stack
      _nextPet();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else {
      // First story in current stack -> go to previous pet stack
      _previousPet();
    }
  }

  void _nextPet() {
    if (_currentPetIndex < _petStacks.length - 1) {
      setState(() {
        _currentPetIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.animateToPage(
        _currentPetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      // All stories completed, close viewer
      context.pop();
    }
  }

  void _previousPet() {
    if (_currentPetIndex > 0) {
      setState(() {
        _currentPetIndex--;
        // When going back to previous pet, start at their last story slide
        _currentStoryIndex = _petStacks[_currentPetIndex].stories.length - 1;
      });
      _pageController.animateToPage(
        _currentPetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      // At the very first story slide, restart it
      _startStory();
    }
  }

  void _pause() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resume() {
    setState(() {
      _isPaused = false;
    });
  }

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(storiesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: storiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load stories: $err',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(storiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stories) {
          if (stories.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
            return const SizedBox.shrink();
          }

          _setupStacks(stories);

          if (_petStacks.isEmpty) {
            return const SizedBox.shrink();
          }

          final activeStack = _petStacks[_currentPetIndex];
          final activeStory = activeStack.stories[_currentStoryIndex];

          return SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Horizontal PageView for swiping between pets
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Let custom tap/slide handle page changes
                  itemCount: _petStacks.length,
                  itemBuilder: (context, petIdx) {
                    final stack = _petStacks[petIdx];
                    // Display the current slide only for the active page
                    final story = (petIdx == _currentPetIndex)
                        ? stack.stories[_currentStoryIndex]
                        : stack.stories.first;

                    return Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: story.imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: networkImageMemCacheWidth(
                              context,
                              MediaQuery.sizeOf(context).width,
                              maxPixels: webNetworkImageMemCacheMax,
                            ),
                            maxWidthDiskCache: networkImageMaxDiskCacheWidth(
                              context,
                              MediaQuery.sizeOf(context).width,
                              maxPixels: webNetworkImageMemCacheMax,
                            ),
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator.adaptive(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error_outline_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Touch controller overlay
                Positioned.fill(
                  child: Row(
                    children: [
                      // Left tap area -> Previous
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _previousStory,
                          onLongPress: _pause,
                          onLongPressUp: _resume,
                        ),
                      ),
                      // Middle long-press area & right tap area -> Next
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _nextStory,
                          onLongPress: _pause,
                          onLongPressUp: _resume,
                        ),
                      ),
                    ],
                  ),
                ),

                // Story Header & Segmented Progress Bars
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Progress bars
                      Row(
                        children: List.generate(
                          activeStack.stories.length,
                          (idx) {
                            double widthFactor = 0.0;
                            if (idx < _currentStoryIndex) {
                              widthFactor = 1.0;
                            } else if (idx == _currentStoryIndex) {
                              widthFactor = _progress;
                            }

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(70),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: widthFactor.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Pet Info
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _timer?.cancel();
                                final savedProgress = _progress;
                                context.push('/social/profile/${activeStack.petId}').then((_) {
                                  if (mounted) {
                                    _startStory(fromProgress: savedProgress);
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white.withAlpha(50),
                                    backgroundImage: activeStack.petAvatarUrl != null
                                        ? CachedNetworkImageProvider(activeStack.petAvatarUrl!)
                                        : null,
                                    child: activeStack.petAvatarUrl == null
                                        ? Text(
                                            activeStack.petName.isNotEmpty
                                                ? activeStack.petName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeStack.petName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 3.0,
                                                color: Colors.black45,
                                                offset: Offset(1.0, 1.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _timeAgo(activeStory.createdAt),
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(180),
                                            fontSize: 11,
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 2.0,
                                                color: Colors.black45,
                                                offset: Offset(1.0, 1.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PetStoryStack {
  final String petId;
  final String petName;
  final String? petAvatarUrl;
  final String petSpecies;
  final List<Story> stories;

  const PetStoryStack({
    required this.petId,
    required this.petName,
    this.petAvatarUrl,
    required this.petSpecies,
    required this.stories,
  });

  bool hasUnviewed(String? userId) {
    if (userId == null) return false;
    return stories.any((s) => !s.viewedByUsers.contains(userId));
  }
}

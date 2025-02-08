import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/story_provider.dart';
import '../widgets/story_form.dart';
import '../widgets/growth_story_form.dart';

class HomeScreen extends StatelessWidget {
  final TabController tabController;
  final String userName =
      'Sarah'; // TODO: Make this dynamic based on user settings

  const HomeScreen({
    super.key,
    required this.tabController,
  });

  void _navigateToTab(int index) {
    tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<StoryProvider>(
          builder: (context, storyProvider, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar with Greeting and Notification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Greeting
                    Text(
                      l10n.goodEvening(userName),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.readyForBedtime,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),

                    const SizedBox(height: 24),

                    // Generate New Story Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: StoryForm(
                                onStoryCreated: () {
                                  Navigator.pop(context);
                                  _navigateToTab(2);
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_fix_high,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              l10n.generateNewStory,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Access Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAccessCard(
                            context,
                            title: l10n.myLibrary,
                            icon: Icons.book_outlined,
                            onTap: () => _navigateToTab(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickAccessCard(
                            context,
                            title: l10n.growthStories,
                            icon: Icons.emoji_events_outlined,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => GrowthStoryForm(
                                  onStoryCreated: () {},
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recent Stories Section
                    Text(
                      l10n.recentStories,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // Recent Story Cards
                    Column(
                      children: [
                        _buildRecentStoryCard(
                          context,
                          title: 'The Magic Forest Adventure',
                          lastRead: l10n.lastRead('Yesterday'),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentStoryCard(
                          context,
                          title: 'Dragon\'s Best Friend',
                          lastRead: l10n.lastRead('2 days ago'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.grey[800]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentStoryCard(
    BuildContext context, {
    required String title,
    required String lastRead,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Text(
                'Story Illustration',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last read: $lastRead',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:magical_stories/screens/growth_stories_screen.dart';
import 'dart:io' show Platform;
import 'home_screen.dart';
import 'stories_screen.dart';
import 'story_generation_screen.dart';
import 'library_screen.dart';
import 'parental_controls_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final bool isIOS = Platform.isIOS;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            HomeScreen(tabController: _tabController),
            const GrowthStoriesScreen(),
            const StoriesScreen(),
            const LibraryScreen(),
            const ParentalControlsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: isIOS
              ? CupertinoTabBar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.trending_up),
                      label: 'Growth',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.auto_stories),
                      label: 'Read',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_books),
                      label: 'Library',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.security),
                      label: 'Controls',
                    ),
                  ],
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    _tabController.animateTo(index);
                  },
                  currentIndex: _currentIndex,
                )
              : TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.home),
                      text: 'Home',
                    ),
                    Tab(
                      icon: Icon(Icons.create),
                      text: 'Create',
                    ),
                    Tab(
                      icon: Icon(Icons.auto_stories),
                      text: 'Read',
                    ),
                    Tab(
                      icon: Icon(Icons.library_books),
                      text: 'Library',
                    ),
                    Tab(
                      icon: Icon(Icons.security),
                      text: 'Controls',
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

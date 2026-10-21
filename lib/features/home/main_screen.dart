import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../post/post_detail_sheet.dart';
import '../post/post_feed_view.dart';
import 'home_app_bar.dart';
import 'home_bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _openPost(int id) {
    showPostDetailSheet(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = HomeAppBar.headerHeightOf(context);

    return Scaffold(
      extendBody: true,
      body: HomeAppBar(
        title: widget.title,
        child: _selectedIndex == 0
            ? PostFeedView(
                contentInsetTop: headerHeight,
                onOpenPost: _openPost,
              )
            : Center(
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: HomeBottomNavigation(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        ),
      ),
    );
  }
}

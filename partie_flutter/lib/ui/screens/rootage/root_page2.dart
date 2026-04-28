import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class RootPage2 extends StatefulWidget {
  const RootPage2({super.key});

  @override
  State<RootPage2> createState() => _RootPage2State();
}

class _RootPage2State extends State<RootPage2> {
  int _bottomNavIndex = 0;

  // List of pages
  final List<Widget> _pages = [

  ];

  // List of icons
  final List<IconData> _iconList = [
    Icons.home,
    Icons.percent,
    Icons.person,
  ];

  // List of titles

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _pages,
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: Colors.green,
        activeColor: Colors.green,
        inactiveColor: Colors.black.withOpacity(0.5),
        icons: _iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }
}

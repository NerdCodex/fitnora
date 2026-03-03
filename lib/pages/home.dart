import 'package:fitnora/pages/food/food.dart';
import 'package:fitnora/pages/profile/profile.dart';
import 'package:fitnora/pages/workout/workout.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final _profileKey = GlobalKey<ProfilePageState>();

  late final List<Widget> _tabs = [const WorkoutPage(), const FoodPage(), ProfilePage(key: _profileKey)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // preserves state
        index: _pageIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _pageIndex,
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
          // Reload profile data when switching to the profile tab
          if (index == 2) {
            _profileKey.currentState?.reload();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            label: "Workout",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: "Food",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

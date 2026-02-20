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

  static const List<Widget> _tabs = [WorkoutPage(), FoodPage(), ProfilePage()];

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

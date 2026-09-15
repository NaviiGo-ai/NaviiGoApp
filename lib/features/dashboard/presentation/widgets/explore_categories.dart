import 'package:flutter/material.dart';

class ExploreCategories extends StatelessWidget {
  ExploreCategories({super.key});

  final List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.directions_walk_rounded,
      'color': Colors.orangeAccent.withAlpha(100),
    },
    {'icon': Icons.park_rounded, 'color': Colors.greenAccent.withAlpha(100)},
    {'icon': Icons.terrain_rounded, 'color': Colors.brown.withAlpha(100)},
    {
      'icon': Icons.holiday_village_rounded,
      'color': Colors.redAccent.withAlpha(100),
    },
    {
      'icon': Icons.water_drop_rounded,
      'color': Colors.blueAccent.withAlpha(100),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Explore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: categories[index]['color'],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      categories[index]['icon'],
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

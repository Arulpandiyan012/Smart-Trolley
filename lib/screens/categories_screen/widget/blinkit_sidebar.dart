import 'package:flutter/material.dart';

class BlinkitSidebar extends StatefulWidget {
  final Function(int) onCategorySelected;
  const BlinkitSidebar({Key? key, required this.onCategorySelected}) : super(key: key);

  @override
  State<BlinkitSidebar> createState() => _BlinkitSidebarState();
}

class _BlinkitSidebarState extends State<BlinkitSidebar> {
  int selectedIndex = 0;

  // STATIC DATA FOR DEMO - Replace with dynamic list if you have it
  final List<Map<String, dynamic>> categories = [
    {"name": "All", "icon": "assets/images/placeholder.png"},
    {"name": "Fresh Vegetables", "icon": "assets/images/veg.png"},
    {"name": "Fresh Fruits", "icon": "assets/images/fruit.png"},
    {"name": "Exotics", "icon": "assets/images/exotic.png"},
    {"name": "Seasonal", "icon": "assets/images/season.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, // Fixed width for sidebar
      color: const Color(0xFFF3F4F6), // Light grey background
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => selectedIndex = index);
              widget.onCategorySelected(index);
            },
            child: Container(
              height: 100, // Taller items like Blinkit
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: isSelected 
                  ? const Border(left: BorderSide(color: Color(0xFF0C831F), width: 4))
                  : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular Image Container
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    // Replace Icon with Image.network or Image.asset
                    child: Icon(Icons.eco, color: isSelected ? const Color(0xFF0C831F) : Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
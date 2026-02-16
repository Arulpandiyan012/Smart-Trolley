import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class BlinkitCategoryGrid extends StatelessWidget {
  final List<dynamic> categories; // Expects list of maps {title, image, link}
  final Function(String link, String title)? onTap;

  const BlinkitCategoryGrid({
    Key? key, 
    required this.categories,
    this.onTap,
  }) : super(key: key);

  Color _getCategoryBgColor(String name, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final n = name.toLowerCase();
    
    // 🟢 JUICY VIBRANT PALETTE
    Color baseColor;
    if (n.contains('fruit') || n.contains('seasonal') || n.contains('apple')) baseColor = const Color(0xFFC6FF00); // Electric Lime
    else if (n.contains('veg') || n.contains('farm') || n.contains('spa')) baseColor = const Color(0xFF00E676); // Green Accent 400
    else if (n.contains('dairy') || n.contains('egg') || n.contains('milk') || n.contains('breakfast')) baseColor = const Color(0xFF00B0FF); // Light Blue Accent 400
    else if (n.contains('bread') || n.contains('bakery') || n.contains('pavana')) baseColor = const Color(0xFFD500F9); // Purple Accent 400
    else if (n.contains('snack') || n.contains('munch') || n.contains('chips') || n.contains('biscuit')) baseColor = const Color(0xFFFF9100); // Orange Accent 400
    else if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('soft drink')) baseColor = const Color(0xFF651FFF); // Deep Purple Accent 400
    else if (n.contains('sweet') || n.contains('chocolate') || n.contains('bakery') || n.contains('cake')) baseColor = const Color(0xFFF50057); // Pink Accent 400
    else if (n.contains('meat') || n.contains('fish') || n.contains('chicken') || n.contains('non veg')) baseColor = const Color(0xFFFF5252); // Red Accent 200
    else if (n.contains('tea') || n.contains('coffee')) baseColor = const Color(0xFF795548); // Brown
    else if (n.contains('baby') || n.contains('child') || n.contains('diaper')) baseColor = const Color(0xFF00E5FF); // Cyan Accent 400
    else if (n.contains('care') || n.contains('beauty') || n.contains('face') || n.contains('personal')) baseColor = const Color(0xFFFF4081); // Pink Accent 200
    else if (n.contains('kitchen')) baseColor = const Color(0xFF1DE9B6); // Teal Accent 400
    else if (n.contains('home') || n.contains('clean') || n.contains('household')) baseColor = const Color(0xFFFFEA00); // Yellow Accent 400
    else if (n.contains('pet') || n.contains('dog') || n.contains('cat')) baseColor = const Color(0xFFFFC400); // Amber Accent 400
    else if (n.contains('oil') || n.contains('ghee')) baseColor = const Color(0xFF90A4AE); // Blue Grey
    else if (n.contains('spice') || n.contains('masala') || n.contains('powder')) baseColor = const Color(0xFFFFAB40); // Orange Accent 200
    else if (n.contains('grocery') || n.contains('staple') || n.contains('dal') || n.contains('atta')) baseColor = const Color(0xFFBDBDBD); // Grey
    else baseColor = const Color(0xFFE0E0E0);

    if (isDark) {
      return Color.alphaBlend(baseColor.withOpacity(0.18), const Color(0xFF2C2C2C));
    }
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return SkeletonLoader(
        highlightColor: Theme.of(context).highlightColor,
        baseColor: Theme.of(context).scaffoldBackgroundColor,
        builder: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, 
            childAspectRatio: 0.74, 
            crossAxisSpacing: 10,
            mainAxisSpacing: 16,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 40,
                  color: Colors.white,
                ),
              ],
            );
          },
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        childAspectRatio: 0.74, 
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length > 8 ? 8 : categories.length, 
      itemBuilder: (context, index) {
        final cat = categories[index];
        final title = cat['title'] ?? '';
        final imageUrl = cat['image'] ?? '';
        final link = cat['link'] ?? '';
        final icon = cat['icon'] as IconData?;
        final baseColor = _getCategoryBgColor(title, context);

        return InkWell(
          onTap: () => onTap?.call(link, title),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        baseColor.withOpacity(0.95), // Bright Top
                        baseColor, // Core
                        baseColor.withOpacity(0.85), // Darker bottom for depth
                      ],
                    ),
                    boxShadow: [
                      // 1. Bottom shadow for lift
                      BoxShadow(
                        color: baseColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                        spreadRadius: -2,
                      ),
                      // 2. Subtle top highlight for 3D rim effect
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 0,
                        offset: const Offset(0, -1),
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // --- Subtle Inner Glow ---
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                          ),
                        ),
                      ),
                      
                      // --- The Content ---
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0), 
                          child: imageUrl.isNotEmpty 
                            ? Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: ImageView(url: imageUrl, fit: BoxFit.contain)
                              )
                            : Icon(
                                icon ?? Icons.category_outlined,
                                size: 32,
                                color: Colors.white,
                                shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.2,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

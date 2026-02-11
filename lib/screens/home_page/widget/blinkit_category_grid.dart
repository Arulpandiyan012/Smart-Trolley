import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';

class BlinkitCategoryGrid extends StatelessWidget {
  final List<dynamic> categories; // Expects list of maps {title, image, link}
  final Function(String link, String title)? onTap;

  const BlinkitCategoryGrid({
    Key? key, 
    required this.categories,
    this.onTap,
  }) : super(key: key);

  Color _getCategoryBgColor(String name) {
    final n = name.toLowerCase();
    
    if (n.contains('fruit') || n.contains('seasonal') || n.contains('apple')) return const Color(0xFFE8F5E9); // Light Green/Fruit
    if (n.contains('veg') || n.contains('farm') || n.contains('spa')) return const Color(0xFFF1F8E9); // Soft Lime
    if (n.contains('dairy') || n.contains('egg') || n.contains('milk') || n.contains('breakfast')) return const Color(0xFFE3F2FD); // Light Blue
    if (n.contains('bread') || n.contains('bakery') || n.contains('pavana')) return const Color(0xFFF3E5F5); // Light Purple/Bakery
    if (n.contains('snack') || n.contains('munch') || n.contains('chips') || n.contains('biscuit')) return const Color(0xFFFFF3E0); // Light Orange
    if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('soft drink')) return const Color(0xFFF3E5F5); // Light Purple
    if (n.contains('sweet') || n.contains('chocolate') || n.contains('bakery') || n.contains('cake')) return const Color(0xFFFCE4EC); // Light Pink
    if (n.contains('meat') || n.contains('fish') || n.contains('chicken') || n.contains('non veg')) return const Color(0xFFFFEBEE); // Light Red
    if (n.contains('tea') || n.contains('coffee')) return const Color(0xFFEFEBE9); // Light Brown
    if (n.contains('baby') || n.contains('child') || n.contains('diaper')) return const Color(0xFFE0F7FA); // Light Cyan
    if (n.contains('care') || n.contains('beauty') || n.contains('face') || n.contains('personal')) return const Color(0xFFFFF7FB); // Very Soft Pink/Care
    if (n.contains('kitchen')) return const Color(0xFFE0F2F1); // Teal Light/Kitchen
    if (n.contains('home') || n.contains('clean') || n.contains('household')) return const Color(0xFFFFFDE7); // Light Yellow
    if (n.contains('pet') || n.contains('dog') || n.contains('cat')) return const Color(0xFFFFECB3); // Amber/Light Pet
    if (n.contains('oil') || n.contains('ghee')) return const Color(0xFFF1F4F9); // Soft Blue-Grey/Oil
    if (n.contains('spice') || n.contains('masala') || n.contains('powder')) return const Color(0xFFFFF3E0); // Light Orange/Clay for Spice
    if (n.contains('grocery') || n.contains('staple') || n.contains('dal') || n.contains('atta')) return const Color(0xFFF5F5F5); // Greyish Grocery
    
    return const Color(0xFFF4F6F8); // Default Greyish
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    // To ensure a "2-row" look, we might want to limit items or wrap in a specific height
    // but a GridView with crossAxisCount already handles rows.
    // Trendy look usually has 4 or 5 items per row.
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        childAspectRatio: 0.78, 
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length > 8 ? 8 : categories.length, // Limit to 8 for neat 2-row look if many
      itemBuilder: (context, index) {
        final cat = categories[index];
        final title = cat['title'] ?? '';
        final imageUrl = cat['image'] ?? '';
        final link = cat['link'] ?? '';
        final icon = cat['icon'] as IconData?;

        return InkWell(
          onTap: () => onTap?.call(link, title),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Image/Icon Container with Pastel Background
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getCategoryBgColor(title),
                    borderRadius: BorderRadius.circular(16), // Trendy rounded
                    border: Border.all(color: Colors.black.withOpacity(0.02), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), 
                      child: imageUrl.isNotEmpty 
                        ? ImageView(
                            url: imageUrl,
                            fit: BoxFit.contain, 
                          )
                        : Icon(
                            icon ?? Icons.category_outlined,
                            size: 28,
                            color: Colors.black54,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Title
              SizedBox(
                height: 28,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: Colors.black87,
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

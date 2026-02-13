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

  Color _getCategoryBgColor(String name, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final n = name.toLowerCase();
    
    Color baseColor;
    if (n.contains('fruit') || n.contains('seasonal') || n.contains('apple')) baseColor = const Color(0xFFE8F5E9); 
    else if (n.contains('veg') || n.contains('farm') || n.contains('spa')) baseColor = const Color(0xFFF1F8E9); 
    else if (n.contains('dairy') || n.contains('egg') || n.contains('milk') || n.contains('breakfast')) baseColor = const Color(0xFFE3F2FD); 
    else if (n.contains('bread') || n.contains('bakery') || n.contains('pavana')) baseColor = const Color(0xFFF3E5F5); 
    else if (n.contains('snack') || n.contains('munch') || n.contains('chips') || n.contains('biscuit')) baseColor = const Color(0xFFFFF3E0); 
    else if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('soft drink')) baseColor = const Color(0xFFF3E5F5); 
    else if (n.contains('sweet') || n.contains('chocolate') || n.contains('bakery') || n.contains('cake')) baseColor = const Color(0xFFFCE4EC); 
    else if (n.contains('meat') || n.contains('fish') || n.contains('chicken') || n.contains('non veg')) baseColor = const Color(0xFFFFEBEE); 
    else if (n.contains('tea') || n.contains('coffee')) baseColor = const Color(0xFFEFEBE9); 
    else if (n.contains('baby') || n.contains('child') || n.contains('diaper')) baseColor = const Color(0xFFE0F7FA); 
    else if (n.contains('care') || n.contains('beauty') || n.contains('face') || n.contains('personal')) baseColor = const Color(0xFFFFF7FB); 
    else if (n.contains('kitchen')) baseColor = const Color(0xFFE0F2F1); 
    else if (n.contains('home') || n.contains('clean') || n.contains('household')) baseColor = const Color(0xFFFFFDE7); 
    else if (n.contains('pet') || n.contains('dog') || n.contains('cat')) baseColor = const Color(0xFFFFECB3); 
    else if (n.contains('oil') || n.contains('ghee')) baseColor = const Color(0xFFF1F4F9); 
    else if (n.contains('spice') || n.contains('masala') || n.contains('powder')) baseColor = const Color(0xFFFFF3E0); 
    else if (n.contains('grocery') || n.contains('staple') || n.contains('dal') || n.contains('atta')) baseColor = const Color(0xFFF5F5F5); 
    else baseColor = const Color(0xFFF4F6F8);

    if (isDark) {
      // In dark mode, we want a very subtle version of these colors
      return Color.alphaBlend(baseColor.withOpacity(0.1), const Color(0xFF1E1E1E));
    }
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

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
      itemCount: categories.length > 8 ? 8 : categories.length, 
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
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getCategoryBgColor(title, context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05), width: 1),
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
                            color: Theme.of(context).dividerColor,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
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

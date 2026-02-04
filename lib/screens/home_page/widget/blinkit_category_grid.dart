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

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columns like Blinkit
        childAspectRatio: 0.75, // Taller for Image + Text
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final title = cat['title'] ?? '';
        final imageUrl = cat['image'] ?? '';
        final link = cat['link'] ?? '';

        return GestureDetector(
          onTap: () => onTap?.call(link, title),
          child: Column(
            children: [
              // Image Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FB), // Light Blue/Grey background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageView(
                      url: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

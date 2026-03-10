import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class BestsellersCategoryGrid extends StatelessWidget {
  final List<dynamic> categories; // Root categories
  final Function(String link, String title, dynamic cat)? onTap;

  const BestsellersCategoryGrid({
    Key? key, 
    required this.categories,
    this.onTap,
  }) : super(key: key);

  String _catLabel(dynamic cat) {
    try { final v = (cat as dynamic).name;  if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
    try { final v = (cat as dynamic).label; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
    if (cat is Map) {
      final v = cat['name'] ?? cat['label'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String _catSlug(dynamic cat) {
    try { final v = (cat as dynamic).slug; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
    if (cat is Map) {
      final v = cat['slug'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String _catImage(dynamic cat) {
    try { final v = (cat as dynamic).bannerUrl; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
    try { final v = (cat as dynamic).imageUrl; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
    if (cat is Map) {
      final v = cat['bannerUrl'] ?? cat['imageUrl'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  List<dynamic> _catChildren(dynamic cat) {
    try { final v = (cat as dynamic).children; if (v is List) return v; } catch (_) {}
    if (cat is Map) {
      final v = cat['children'];
      if (v is List) return v;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink(); // Could add skeleton here
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            "Bestsellers",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Roboto',
              color: Theme.of(context).textTheme.titleLarge?.color,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          // 3 Column Grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              childAspectRatio: 0.65, // Adjust to fit 2x2 grid + text
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length > 6 ? 6 : categories.length, // Max 6 cards
            itemBuilder: (context, index) {
              final cat = categories[index];
              final title = _catLabel(cat);
              final link = _catSlug(cat);
              final children = _catChildren(cat);
              final childrenCount = children.length;
              
              // Get up to 4 subcategory images
              List<String> subImages = [];
              for (int i = 0; i < 4; i++) {
                if (i < childrenCount) {
                  String img = _catImage(children[i]);
                  if (img.isNotEmpty) {
                    if (img.contains('/storage/')) {
                      img = img.replaceFirst('/storage/', '/image_proxy.php?path=');
                    }
                    subImages.add(img);
                  } else {
                    subImages.add(''); // Blank placeholder
                  }
                } else {
                  subImages.add(''); // Fill remaining with blanks
                }
              }

              final extraCount = childrenCount > 4 ? childrenCount - 4 : 0;

              return InkWell(
                onTap: () => onTap?.call(link, title, cat),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // 2x2 Grid Container
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : Theme.of(context).secondaryHeaderColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(4),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: 4,
                              itemBuilder: (context, imgIndex) {
                                final imgUrl = subImages[imgIndex];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2)
                                    ],
                                  ),
                                  child: imgUrl.isNotEmpty 
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(imgUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.category, size: 16, color: Colors.grey)))
                                    : const Center(child: Icon(Icons.image_outlined, size: 16, color: Colors.black12)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      // "+X more" Badge (Overlap visually or just text below grid)
                      (extraCount > 0)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]
                            ),
                            child: Text(
                              "+$extraCount more",
                              style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          )
                        : const SizedBox(height: 12), // Spacer
                        
                      // Title
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                          child: Center(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

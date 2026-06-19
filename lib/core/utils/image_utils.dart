// Utility class for dynamic image URL selection based on place category/name

class ImageUtils {
  /// Dynamically maps category or name keywords to appropriate Unsplash illustration cards
  static String getPlaceholderImage(String category, String name) {
    final cat = category.toLowerCase();
    final nm = name.toLowerCase();

    if (cat.contains("waterfall") || nm.contains("waterfall") || nm.contains("falls")) {
      return "https://images.unsplash.com/photo-1482862549707-f63cb32c5fd9?q=80&w=600&auto=format&fit=crop"; // Waterfall
    } else if (cat.contains("beach") || cat.contains("coast") || cat.contains("ocean") || nm.contains("beach") || nm.contains("bay")) {
      return "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop"; // Beach
    } else if (cat.contains("temple") || cat.contains("cultur") || cat.contains("histor") || cat.contains("fort") || nm.contains("temple") || nm.contains("sigiriya") || nm.contains("fort")) {
      return "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=600&auto=format&fit=crop"; // Culture / Heritage
    } else if (cat.contains("hike") || cat.contains("mount") || cat.contains("peak") || cat.contains("forest") || cat.contains("natur") || nm.contains("peak") || nm.contains("mountain") || nm.contains("ella")) {
      return "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=600&auto=format&fit=crop"; // Hiking / Nature
    } else if (cat.contains("park") || cat.contains("safari") || cat.contains("wild") || nm.contains("yala") || nm.contains("park")) {
      return "https://images.unsplash.com/photo-1581888227599-779811939961?q=80&w=600&auto=format&fit=crop"; // Wildlife / Safari
    }
    return "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=600&auto=format&fit=crop"; // Default Sri Lanka tea estate
  }
}

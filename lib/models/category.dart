class Category {
  final String name;
  final String? icon; // For emojis or icons

  Category({required this.name, this.icon});

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      name: data['name'] ?? '',
      icon: data['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}
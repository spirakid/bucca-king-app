import 'package:cloud_firestore/cloud_firestore.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all menu items
  Stream<List<MenuItem>> getMenuItems() {
    return _firestore
        .collection('menu_items')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuItem.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get menu items by category
  Stream<List<MenuItem>> getMenuItemsByCategory(String category) {
    return _firestore
        .collection('menu_items')
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuItem.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Add menu item (for admin)
  Future<String> addMenuItem(MenuItem item) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('menu_items')
          .add(item.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding menu item: $e');
      rethrow;
    }
  }

  // Update menu item (for admin)
  Future<void> updateMenuItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('menu_items')
          .doc(itemId)
          .update(updates);
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  // Delete menu item (for admin)
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _firestore
          .collection('menu_items')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error deleting menu item: $e');
      rethrow;
    }
  }

  // Toggle availability (for admin)
  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    try {
      await _firestore
          .collection('menu_items')
          .doc(itemId)
          .update({'isAvailable': isAvailable});
    } catch (e) {
      print('Error toggling availability: $e');
      rethrow;
    }
  }

  // Get single menu item
  Future<MenuItem?> getMenuItem(String itemId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('menu_items')
          .doc(itemId)
          .get();
      
      if (doc.exists) {
        return MenuItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting menu item: $e');
      return null;
    }
  }

  // Search menu items
  Stream<List<MenuItem>> searchMenuItems(String query) {
    return _firestore
        .collection('menu_items')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var items = snapshot.docs.map((doc) {
        return MenuItem.fromMap(doc.id, doc.data());
      }).toList();
      
      // Filter by search query
      if (query.isNotEmpty) {
        items = items.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase()) ||
                 item.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      
      return items;
    });
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final String prepTime;
  final List<String> ingredients;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.isAvailable = true,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.prepTime = '20-30 min',
    this.ingredients = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'prepTime': prepTime,
      'ingredients': ingredients,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 4.5).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      prepTime: map['prepTime'] ?? '20-30 min',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
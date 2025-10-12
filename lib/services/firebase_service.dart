import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new order
  Future<String> createOrder(OrderModel order) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('orders')
          .add(order.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Get all orders for a user
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get all orders (for admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Get single order
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Delete order (for testing)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }
}
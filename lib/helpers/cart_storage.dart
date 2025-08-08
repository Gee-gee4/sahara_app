import 'package:flutter/material.dart';

class CartItem {
  CartItem({
    String? uniqueIdentifier,
    required this.productId, // Add this parameter
    required this.productName,
    required this.price,
    required this.quantity,
  }) {
    uniqueId = uniqueIdentifier ?? '$productId:$quantity';
  }

  late String uniqueId; // For transaction tracking
  final int productId; // Add this for discount matching
  final String productName;
  final double price;
  double quantity;

  double get totalAmount => price * quantity;
}

class CartStorage extends ChangeNotifier {
  static CartStorage? _cache;

  CartStorage._();

  factory CartStorage() {
    _cache ??= CartStorage._();
    return _cache!;
  }
  final List<CartItem> cartItems = [];

  // Update this method to include productId
  void addToCart(
    int productId,
    String name,
    double unitPrice,
    double quantity,
  ) {
    final index = cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      cartItems[index].quantity += quantity;
    } else {
      cartItems.add(
        CartItem(
          productId: productId,
          productName: name,
          price: unitPrice,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  // Update this method to use productId for finding items
  void updateQuantity(int productId, double newQuantity) {
    final index = cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (newQuantity < 1) {
        cartItems.removeAt(index);
      } else {
        cartItems[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  // Update this method to use productId
  void decrementQuantity(int productId) {
    final index = cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      final item = cartItems[index];

      final isWhole = item.quantity % 1 == 0;

      if (isWhole) {
        // Whole numbers logic — remove at 1
        if (item.quantity > 1) {
          item.quantity -= 1;
        } else {
          cartItems.removeAt(index);
        }
      } else {
        // Decimal logic — only reduce if still above 1
        if (item.quantity > 1) {
          item.quantity -= 1;
        } else {
          // If already <= 1, stop decrementing — don't allow < 1
          // and don't remove
        }
      }
      notifyListeners();
    }
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }

  double getTotalPrice() {
    return CartStorage().cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }
}

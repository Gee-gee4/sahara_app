import 'package:flutter/material.dart';

class CartItem {
  CartItem({
    String? uniqueIdentifier,
    required this.productId, 
    required this.productName,
    required this.price,
    required this.quantity,
    required this.fixedTotal,
  }) :
    uniqueId = uniqueIdentifier ?? '$productId:$quantity';
  

  final String uniqueId; // For transaction tracking
  final int productId; // Add this for discount matching
  final String productName;
  final double price;
  double quantity;
   final double fixedTotal;

    double get totalAmount => fixedTotal;
  // double get totalAmount => price * quantity;
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
    double quantity, {
      double? fixedTotal,
    bool isTransaction = true, // Add this parameter
  }) {
    if (isTransaction) {
      // For transactions: Always add as NEW item with unique ID
      final uniqueId = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      cartItems.add(
        CartItem(
          uniqueIdentifier: uniqueId, // Pass unique ID
          productId: productId,
          productName: name,
          price: unitPrice,
          quantity: quantity,
          fixedTotal: fixedTotal ?? unitPrice * quantity, 
          
        ),
      );
    } else {
      // For regular products: Use existing logic (update quantity if same product)
      final index = cartItems.indexWhere((item) => item.productId == productId);
      if (index != -1) {
        cartItems[index].quantity += quantity;
      } else {
        cartItems.add(CartItem(productId: productId, productName: name, price: unitPrice, quantity: quantity,fixedTotal: unitPrice * quantity,));
      }
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
  return cartItems.fold(
    0,
    (sum, item) => sum + item.fixedTotal, // ✅ Use fixedTotal instead of calculating
  );
}
}

import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double unitPrice;
  double quantity;

  CartItem({required this.name, required this.unitPrice, required this.quantity});
}

class CartStorage extends ChangeNotifier {
  static CartStorage? _cache;

  CartStorage._();

  factory CartStorage(){
    _cache ??= CartStorage._();
    return _cache!;
  }
  final List<CartItem> cartItems = [];

  void addToCart(String name, double unitPrice, double quantity) {
    final index = cartItems.indexWhere((item) => item.name == name);
    if (index != -1) {
      cartItems[index].quantity += quantity;
    } else {
      cartItems.add(CartItem(name: name, unitPrice: unitPrice, quantity: quantity));
    }
    notifyListeners();
  }

  void updateQuantity(String name, double newQuantity) {
    final index = cartItems.indexWhere((item) => item.name == name);
    if (index != -1) {
      if (newQuantity < 1) {
        cartItems.removeAt(index);
      } else {
        cartItems[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }

  // static void decrementQuantity(String name) {
  //   final index = cartItems.indexWhere((item) => item.name == name);
  //   if (index != -1) {
  //     if (cartItems[index].quantity > 1) {
  //       cartItems[index].quantity -= 1;
  //     } else {
  //       cartItems.removeAt(index);
  //     }
  //   }
  // }
  void decrementQuantity(String name) {
    final index = cartItems.indexWhere((item) => item.name == name);
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
          // and don’t remove
        }
      }
      notifyListeners();
    }
  }
}

class CartItem {
  final String name;
  final double price;
  final String productId;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.productId,
    this.quantity = 1,
  });
}

class CartStorage {
  static final List<CartItem> cartItems = [];

  static void addToCart(String name, double price, String productId) {
    final index = cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      cartItems[index].quantity += 1;
    } else {
      cartItems.add(CartItem(name: name, price: price, productId: productId));
    }
  }

  static void updateQuantity(String productId, int newQuantity) {
    final index = cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1 && newQuantity >= 1) {
      cartItems[index].quantity = newQuantity;
    }
  }

  static void clearCart() {
    cartItems.clear();
  }
}

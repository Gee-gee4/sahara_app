class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});
}

class CartStorage {
  static final List<CartItem> cartItems = [];

  static void addToCart(String name, double price, String productId) {
    final index = cartItems.indexWhere((item) => item.name == name);
    if (index != -1) {
      cartItems[index].quantity += 1;
    } else {
      cartItems.add(CartItem(name: name, price: price));
    }
  }

  static void updateQuantity(String name, int newQuantity) {
    final index = cartItems.indexWhere((item) => item.name == name);
    if (index != -1 && newQuantity >= 1) {
      cartItems[index].quantity = newQuantity;
    }
  }

  static void clearCart() {
    cartItems.clear();
  }
}
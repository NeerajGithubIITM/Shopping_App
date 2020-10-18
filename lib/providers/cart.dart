import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class Cart with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    // This getter returns number of products in the cart. (for products_overview_screen and cart_screen)
    // Note: Not the total number of items but only the number of distinct products.
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
    String productId,
    double price,
    String title,
  ) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (currentCartItem) => CartItem(
          id: currentCartItem.id,
          title: currentCartItem.title,
          price: currentCartItem.price,
          quantity: currentCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          title: title,
          price: price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId)
  // This is for the UNDO in the SnackBar.
  {
    if (!_items.containsKey(productId)) {
      return; // Do nothing if it wasnt in the cart before
    }
    if (_items[productId].quantity == 1) {
      removeItem(
          productId); // Remove from cart if the recent addition was the first one for that product.
    }
    if (_items[productId].quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
        ),
      );
    }
    notifyListeners();
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}

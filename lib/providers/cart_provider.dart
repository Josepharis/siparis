import 'package:flutter/material.dart';
import 'package:siparis/models/product.dart';
import 'package:siparis/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalItems => itemCount;

  double get totalAmount => _items.values.fold(
        0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      updateQuantity(product.id, _items[product.id]!.quantity + 1);
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: 1,
      );
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        removeFromCart(productId);
      } else {
        _items[productId] = CartItem(
          product: _items[productId]!.product,
          quantity: quantity,
        );
        notifyListeners();
      }
    }
  }

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

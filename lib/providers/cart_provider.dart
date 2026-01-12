import 'package:flutter/material.dart';
import '../main_screen.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get items => _cartItems;

  double get grandTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.total);
  }


  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
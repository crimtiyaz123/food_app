import 'package:flutter/material.dart';

class CartModel extends ChangeNotifier {
  final Map<String, int> _items = {}; // item -> quantity
  final List<String> _orders = [];

  Map<String, int> get items => _items;
  List<String> get orders => _orders;

  void addItem(String item) {
    if (_items.containsKey(item)) {
      _items[item] = _items[item]! + 1;
    } else {
      _items[item] = 1;
    }
    notifyListeners();
  }

  void removeItem(String item) {
    if (_items.containsKey(item) && _items[item]! > 0) {
      _items[item] = _items[item]! - 1;
      if (_items[item] == 0) _items.remove(item);
      notifyListeners();
    }
  }

  void placeOrder() {
    _items.forEach((item, qty) {
      _orders.add('$item - $qty pcs');
    });
    _items.clear();
    notifyListeners();
  }
}

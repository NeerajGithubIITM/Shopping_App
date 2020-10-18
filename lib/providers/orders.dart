import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Orders with ChangeNotifier {
  final String authToken;
  final String userId;

  Orders(this.authToken, this.userId, this._orders);

  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final url = 'https://flutter-dbconnect.firebaseio.com/orders/$userId.json?auth=$authToken';
    final response = await http.get(url);
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if(extractedData == null) {
      return;
    }
    extractedData.forEach(
      (orderId, orderData) {
        loadedOrders.add(
          OrderItem(
            id: orderId,
            amount: orderData['amount'],
            dateTime: DateTime.parse(orderData['dateTime']),
            products: (orderData['products'] as List<dynamic>) // We know its a list of maps
                .map( // item is a map. So, unwrap its data and put out CartItem widgets (with that data) in a list, which will go into the products argument of OrderItem.
                  (item) => CartItem(
                    id: item['id'],
                    title: item['title'],
                    quantity: item['quantity'],
                    price: item['price'],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = 'https://flutter-dbconnect.firebaseio.com/orders/$userId.json?auth=$authToken';
    final timeStamp = DateTime.now();

    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'amount': total,
            'dateTime': timeStamp.toIso8601String(),
            // Need to store cartProducts data to server. But can't pass objects coz can't be encoded into json.
            // But maps can be. So can lists. So, pass a list of maps
            'products': cartProducts
                .map((cp) => {
                      'id': cp.id,
                      'title': cp.title,
                      'price': cp.price,
                      'quantity': cp.quantity,
                    })
                .toList(),
          },
        ),
      );
      final newOrder = OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        products: cartProducts,
        dateTime: timeStamp,
      );
      _orders.insert(0, newOrder);
      notifyListeners();
    } catch (error) {
      // Pls to do error handling
    }
  }
}

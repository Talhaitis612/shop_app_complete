import 'package:flutter/foundation.dart';

import './cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  //  to fetch and set Orders
  Future<void> fetchAndSetOrders() async {
    final url = Uri.https(
        'flutter-update-37bc7-default-rtdb.firebaseio.com', '/orders.json');
    final response = await http.get(url);
    final List<OrderItem> _loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach(
      (orderId, orderData) {
        _loadedOrders.add(
          OrderItem(
            id: orderId,
            amount: orderData['amount'],
            dateTime: DateTime.parse(orderData['dateTime']),
            // converting the products to list because in the end it was converting to map
            products: (orderData['products'] as List<dynamic>)
                .map((item) => CartItem(
                      id: item['id'],
                      price: item['price'],
                      quantity: item['quantity'],
                      title: item['title'],
                    ))
                .toList(),
          ),
        );
      },
    );
    _orders = _loadedOrders.reversed.toList();
    notifyListeners();
    print(json.encode(response.body));
  }

// to add orders
  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = Uri.https(
        'flutter-update-37bc7-default-rtdb.firebaseio.com', '/orders.json');
    //making  a timeStamp because we want to have the same time on
    // server and on local device
    final timeStamp = DateTime.now();
    final response = await http.post(
      url,
      body: json.encode(
        {
          'amount': total,
          'dateTime': timeStamp.toIso8601String(),
          //products is actually a list that can be encoded to JSON like a map
          // we have to pass cartProducts here which is a list, list of cartItems
          // we need to map these cartItems  into maps and then convert it into List
          'products': cartProducts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        },
      ),
    );

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        dateTime: timeStamp,
        products: cartProducts,
      ),
    );
    notifyListeners();
  }
}

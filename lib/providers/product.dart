// Initially this was under models. But to be able to use its non final isFavorite bool, this was made a provider.
// The provider set up for this class is done in products_grid.dart just above the ProductItem() initialisation in the widget tree so that ProductItem() can be made a listener.
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.imageUrl,
    @required this.price,
    this.isFavorite = false,
  });

  Future<void> toggleFavStatus(String token, String userId) async {
    // Here, we are accepting the token in the function arg passed from the overview screen. (product_item.dart file)
    // A perfectly fine (in fact, a more common) alternative would be to get the token into this class as a property from Products() where we already have the token, and use it in the function. 
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url = 'https://flutter-dbconnect.firebaseio.com/userFavs/$userId/$id.json?auth=$token';
    // Insted of storing this in the products folder, we are creating a folder userFavs, subfolder for each user, subfolders under each user for the products they marked favorite.
    // Now, when a user marks a product favorite, it will be marked fav w.r.t that user only (reducing favorite scope down to each user and not a universal scope)
    // A similar thing will be done with the products and orders.

    try {
      //final response = await http.patch( // Since we only need to send a true/false value, and not modify a field keeping others same, put is better
      final response = await http.put(
        url,
        body: json.encode(
          isFavorite,
        ),
      );
      // Only get() and put() requests throw errors on their own
      // So, here we need to handle manually
      // We could throw a HttpException() custom error and catch it in catch
      // Or lazily do this...

      if (response.statusCode >= 400) {
        isFavorite = oldStatus;
        notifyListeners();
      }
    } catch (error) {
      isFavorite = oldStatus;
      notifyListeners();
      // One can also add user interaction messages here conveying that marking favorite was unsuccessful
      // Or some snackBar, dialog in the widget build itself.
      // Not doing it here.
    }

  }
}

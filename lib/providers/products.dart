import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // to avoid name-clash chances.
import 'product.dart';
import '../models/http_exception.dart';
// Using providers is a part of the State Management solution
// It is used to manage all the data which can change over time, with users interference or not.(i.e change of State)

// The with keyword indicates a mix-in.
// It's kind of inheritance but a lighter version of it, so to speak.
// Some properties are borrowed from the mixed in class but the objects don't become instances of that class.
class Products with ChangeNotifier {
  List<Product> _items = [
    // No need to have a default initialization of list of items coz its going to be loaded from the internet.

    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];
  // The list is not final as items can change.
  // With _, it is made private and can't be accessed directly from outside.
  // But the data is meant to be passed to other classes. So we give out a copy of _items without modifying it directly.

  // And we give out that copy in a getter.
  // This getter gives out the entire list to whichever part of the app it is used in
  List<Product> get items {
    return [..._items];
  }

  // This getter is for products overview screen, to return only favorite items
  // This arrangement doesn't affect the availability of the whole list to any other part of the app, so it works.
  List<Product> get favItems {
    return [..._items.where((prod) => prod.isFavorite).toList()];
  }

  final String authToken;
  final String userId;
  Products(this.authToken, this.userId, this._items);
  // We use ProxyProviders to get data here from Auth() in main.dart
  // But this class must not cease to be a provider. It must still give the items list to all screens that need it.
  // So, it takes items from the previousProducts, a Products() object given by flutter within update: of ProxyProvider()
  // This ensures that, when Auth() changes in its properties, a Products() object is provided with updated properties from Auth()
  // But it continues to provide the same list 'items' which it gets from its previous self.

  Product findById(String id) {
    return _items.firstWhere(
      (prod) => prod.id == id,
    );
  }

  Future<void> fetchProducts({bool filterByUser = false}) async {
    // This is called from products_overview to load the data from the web server each time the page is rendered.

    final filterString = filterByUser ? '&orderBy="userId"&equalTo="$userId"' : '';

    //const url = 'https://flutter-dbconnect.firebaseio.com/products.json'; // Without the token
    final url =
        'https://flutter-dbconnect.firebaseio.com/products.json?auth=$authToken$filterString';
    // Adding auth=token is something firebase supports. Will be different for other APIs.
    // We want to render only the logged in user's products. Better for performance if that filtering happens from server end.
    // And firebase does provide that feature with the orderBy, equalTo keywords. (also note the firebase rules changes required i.e .indexOn)
    // Other APIs might also have that feature. 

    final favoriteUrl = 'https://flutter-dbconnect.firebaseio.com/userFavs/$userId.json?auth=$authToken';
    // We want all the favorites for a particular user, so we aint't going in to the prod id subfolder here.

    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String,
          dynamic>; // Its actually a map in a map. But dart will gibe error if we say Map<String, Map>

      final favoriteResponse = await http.get(favoriteUrl);    
      final extractedFavData = json.decode(favoriteResponse.body);

      final List<Product> serverLoadedProds = [];
      if (extractedData == null) {
        return;
      }
      extractedData.forEach((prodId, prodData) {
        // prodId, the keys of the outer map are our product ids
        // prodData, the maps which are values of the outer map, contain our product data
        serverLoadedProds.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite: extractedFavData == null ? false : extractedFavData[prodId] ?? false, // ?? checks if the value to the left is null. If it is, uses the value on the right.
          // extractedFavData is another simple map with prodId as keys and corresponding product isFavorite staus as values.
        ));
      });

      _items = serverLoadedProds;
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  Future<void> addProduct(Product product) async {
    // making this function return a future of no specific type so that we can use .then on the result of addProduct() in edit_product_screen and call the pop() only once the product is added
    final url =
        'https://flutter-dbconnect.firebaseio.com/products.json?auth=$authToken';
    // products.json at the end is a firebase thing, asking it to create a folder named products. Other APIs will have different requirements.

    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            // 'isFavorite': product.isFavorite, // No need now. We have another folder for this
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'userId': userId // Store user id also with the product to mark who's product it is.
          },
        ),
      );
      final newProduct = Product(
        // id: DateTime.now().toString(), // No need to create unique ids this way. We can use the one returned by the server in the response.
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
      );
      _items.add(newProduct);
      // _items.insert(0, newProduct); Adds at the start of the list.
      notifyListeners();
    } catch (error) {
      throw error;
      // Can use the same async/await, try/catch syntax in edit_product_screen also.
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://flutter-dbconnect.firebaseio.com/products/$id.json?auth=$authToken';
      // Note the difference in this url to the ones in the above functions.
      // The '$id' is to navigate into the folder of the firebase database and access that one product which we want to update.
      // And since doing so makes it no longer constant at compile time but only at run time, it is now final and not const anymore.

      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'price': newProduct.price,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-dbconnect.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];

    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      // Response status codes in 400s indicate that there were some errors with executing the http requests.
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product!');
      // throw is like return, in the sense, no code after it will be executed. Exits the function
    }

    existingProduct = null;

    // This procedure done above is an optional one, called optimistic updating
    // 1. Delete from list, but not yet from memory (that's why stored in another var)
    // 2. Delete from web server. Check if successful
    // 3. If http.delete() fails, roll back i.e undo the delete and readd to list. (no undue loss of data)
    // 4. If successful, remove item from memory also.
  }
}

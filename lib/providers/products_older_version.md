// This is the older version of the addProducts() 
// function in products.dart
// The latest one uses async / await syntax.



Future<void> addProduct(Product product) {

    // making this function return a future of no specific type so that we can use .then on the result of addProduct() in edit_product_screen and call the pop() only once the product is added

    const url = 'https://flutter-dbconnect.firebaseio.com/products.json';

    // products.json at the end is a firebase thing, asking it to create a folder named products. Other APIs will have different requirements.

    return http
        .post(
      url,
      body: json.encode(
        {
          'isFavorite': product.isFavorite,
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
        },
      ),
    ) 
    // As usual, the code in then() is executed once the http request is complete
    // i.e once the folder is created, data stored and the server sends a response.

        .then((response) {
      print(json.decode(response
          .body)); // This returns a map with a key = 'name' and a value which is a unique string.
      final newProduct = Product(

        // id: DateTime.now().toString(), // No need to create unique ids this way. We can use the one returned by the server in the response.

        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
      );
      _items.add(newProduct)
      // _items.insert(0, newProduct); Adds at the start of the list.

      notifyListeners();

      // All the other widgets which are 'listening' to this class are rebuilt on running notifyListeners()
      // So, whenever a modification is done to _items in a function (like addProduct here),
      // running notifyListeners() will make sure that the Listeners get the updated copy of _items through the getter, while the original _items stays here ready for future changes


    }).catchError((error) {
      // Adding catchError here after post and then blocks to catch any error in either of the bloack
      // If there is an error in post(), then() is skipped and it comes right down to catchError().

      throw(error);
      // throws the error to the catch Error in edit products screen.
      // So actually, can do without this catchError()
    });
  }
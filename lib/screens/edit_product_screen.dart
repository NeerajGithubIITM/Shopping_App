import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products.dart';
import '../providers/product.dart';

// User input through forms is a good candidate for making a stateful widget.
// Changes in the inputs made until the actual submission is made is something that the widget must locally take care of.
class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-products';

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageURLFocusNode = FocusNode();
  final _imageURLController = TextEditingController();
  // Generally using forms for inputs does not require the use of controllers
  // But for the image preview, we need the text entered before the form is submitted.
  // So, this controller is for that.

  final _form = GlobalKey<FormState>();
  var _editedProduct = Product(
    id: null,
    title: '',
    description: '',
    imageUrl: '',
    price: 0.0,
  );
  var _isInit = true; // for didChangeDependencies to initialise only once
  var _isLoading = false;

  var _initialValues = {
    'title': '',
    'description': '',
    'price': '',
    'imageUrl': '',
  };

  @override
  void initState() {
    // This drama with the imageURLFocusNode ensures that the image preview is displayed without having to hit the submit button on the keyboard.
    // Even if the user fill up the url first and then goes to another field, the preview must be shown.
    _imageURLFocusNode.addListener(_updateImageURL);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Can't use initState for this... context gibes problems
      final productId = ModalRoute.of(context).settings.arguments as String;
      if (productId != null) {
        _editedProduct =
            Provider.of<Products>(context, listen: false).findById(productId);
        _initialValues = {
          'title': _editedProduct.title,
          'description': _editedProduct.description,
          'price': _editedProduct.price.toString(),
          // 'imageUrl': _editedProduct.imageUrl, // cant use initial value and controller at the same time
          'imageUrl': '',
        };
        _imageURLController.text = _editedProduct.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _imageURLFocusNode.removeListener(_updateImageURL);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageURLController.dispose();
    super.dispose();
  }

  void _updateImageURL() {
    if (!_imageURLFocusNode.hasFocus) {
      setState(() {});
    }
  }

  void _saveForm() {
    final isValid = _form.currentState.validate();
    // runs all the validate methods in the textformfields and returns true if all vaidations return null, i.e no error in any field.

    if (!isValid) {
      return;
    }
    _form.currentState.save();
    // calls all the onSaved methods in the textformfields

    // Show loading indicator when loading.
    setState(() {
      _isLoading = true;
    });

    if (_editedProduct.id != null) {
      // Means we are editing an existing product. So don't add it to the list as a new product.
      Provider.of<Products>(context, listen: false)
          .updateProduct(_editedProduct.id, _editedProduct);
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();
    } else {
      Provider.of<Products>(context, listen: false)
          .addProduct(_editedProduct)
          .catchError((error) {
        return showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text('An error occured'),
              content: Text('Something went wrong.'),
              actions: <Widget>[
                FlatButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Okay'),
                )
              ],
            );
          },
        );
      }).then((_) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();

        // Here, returning the showDialog in catchError is a neat trick
        // If not for that return, catchError would return a random meaningless Future on which .then() runs
        // In that case, .then() would run once dialog was displayed.

        // But returning showDialog, which also happens to return a Future, will return that Future from catchError() which deals with the action to be done after the dialog has been dealt with.
        // In this case, .then() run after the user has interacted with the dialog.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(15),
              child: Form(
                key: _form,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      initialValue: _initialValues['title'],
                      // Explore docs for all its features
                      decoration: InputDecoration(
                        focusColor: Theme.of(context).accentColor,
                        labelText: 'Title',
                        hintText: 'Enter your product title here',
                      ),
                      // The submit button on the keyboard will show a 'next' symbol, indicating it will shift to the next field.
                      textInputAction: TextInputAction.next,

                      // When the 'next' button is tapped on the keyboard, shift form input focus to price field.
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a value for title';
                        }
                        return null; // Meaning no error
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          isFavorite: _editedProduct.isFavorite,
                          title: value,
                          description: _editedProduct.description,
                          imageUrl: _editedProduct.imageUrl,
                          price: _editedProduct.price,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initialValues['price'],
                      decoration: InputDecoration(
                        labelText: 'Price',
                        hintText: 'Enter your product price here',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      focusNode: _priceFocusNode,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode);
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Please enter a positive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          isFavorite: _editedProduct.isFavorite,
                          title: _editedProduct.title,
                          description: _editedProduct.description,
                          imageUrl: _editedProduct.imageUrl,
                          price: double.parse(value),
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initialValues['description'],
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter product description',
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.length < 10) {
                          return 'Description should be atleast 10 characters long';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          isFavorite: _editedProduct.isFavorite,
                          title: _editedProduct.title,
                          description: value,
                          imageUrl: _editedProduct.imageUrl,
                          price: _editedProduct.price,
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          alignment: _imageURLController.text.isEmpty
                              ? Alignment.center
                              : null,
                          height: 100,
                          width: 100,
                          margin: EdgeInsets.only(top: 10, right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child: _imageURLController.text.isEmpty
                              ? Text(
                                  'Enter a URL',
                                  style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 10,
                                  ),
                                )
                              : FittedBox(
                                  child: Image.network(
                                    _imageURLController.text,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: TextFormField(
                            // initialValue: _initialValues['imageUrl'], // can't use initialValue and controller together.
                            decoration: InputDecoration(
                              labelText: 'Image URL',
                              hintText: 'Enter product image URL',
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            controller: _imageURLController,
                            focusNode: _imageURLFocusNode,
                            onFieldSubmitted: (_) => _saveForm(),
                            onSaved: (value) {
                              _editedProduct = Product(
                                id: _editedProduct.id,
                                isFavorite: _editedProduct.isFavorite,
                                title: _editedProduct.title,
                                description: _editedProduct.description,
                                imageUrl: value,
                                price: _editedProduct.price,
                              );
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

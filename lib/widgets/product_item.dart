import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/product_details_screen.dart';
import '../providers/product.dart';
import '../providers/cart.dart';
import '../providers/auth.dart';

class ProductItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authData = Provider.of<Auth>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);
    // final product = Provider.of<Product>(context);
    // This above code is a normal implementation of listener for Product() provider.

    // The below version using Consumer() is another equivalent verion one can use.
    // Note: We are able to set up the listener in the first place because in products_grid.dart, we have defined a provider with ChangeNotifier.value
    return Consumer<Product>(
      // Consumer() being a widget can be wrapped around only that part of the widget tree which needs to rebuild on change in data.
      // Whereas Provider.of triggers rebuilding of the entire build method when something changes.
      // One could use Provider.of to get the data initially and set listen: false to prevent further listens.
      // And then Consumer() can be wrapped around the required widget causing only that widget to rebuild on data/state change.
      builder: (ctx, product, child)
          // The 'child' given by this builder function is used to point to any component of the widget tree wrapped by the consumer which mustn't update with the rest of the wrapped widgets.
          // A tiny optimisation feature
          =>
          ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GridTile(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                ProductDetailsScreen.routeName,
                arguments: product.id,
              );
            },
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          footer: GridTileBar(
            leading: IconButton(
              icon: Icon(
                  product.isFavorite ? Icons.favorite : Icons.favorite_border),
              color: Colors.redAccent[700],
              onPressed: () {
                product.toggleFavStatus(authData.token, authData.userId);
              },
            ),
            backgroundColor: Colors.black87,
            title: Text(
              product.title,
              textAlign: TextAlign.center,
            ),
            trailing: IconButton(
              icon: Icon(Icons.shopping_cart),
              color: Colors.redAccent[700],
              onPressed: () {
                cart.addItem(product.id, product.price, product.title);
                Scaffold.of(context).hideCurrentSnackBar();
                // If there is a snackbar already (from the previous tapping), close it and display the latest one.
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added item to cart'),
                    duration: Duration(seconds: 2),
                    action: SnackBarAction(
                      textColor: Theme.of(context).primaryColor,
                      label: 'UNDO',
                      onPressed: () {
                        cart.removeSingleItem(product.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Why did we not make this widget a Stateful one to manage the toggling of isFavorite? Why providers?
// The favorite aspect of a product isn't something related to this widget only.
// If there was a property which wouldn't be required anywhere else but only in that widget, then we must make that a Stateful Widget and manage the state within that class.
// But here, it isn't a Local Widget state but an App Wide state. And that is why providers (no need to use constructors).
// ** Don't use providers to manage a local state. **

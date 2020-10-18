import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/product_item.dart';
import '../providers/products.dart';

class ProductsGrid extends StatelessWidget {
  final bool showFavs;

  ProductsGrid(this.showFavs);

  @override
  Widget build(BuildContext context) {
    // Provider.of can be set up in a widget whose direct or indirect parent sets up a provider (here it's the main.dart file)
    // This makes this widget a Listener. When the provider is modified, this build function will run, but not that of its parent i.e products_overview_screen.dart
    final productsData = Provider.of<Products>(context);
    final loadedProducts =
        showFavs ? productsData.favItems : productsData.items;
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: loadedProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // Fixes the number of columns.
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
        // Setting up Product() as a provider here so that ProductItem() can listen in to changes in the isFavorite bool.
        // Each child ProductItem() requires a different Product() provider.
        // Each loadedProducts[i] acting as a provider serves that purpose. 
        value: loadedProducts[i],
        child: ProductItem(
            // Now that we are using Product() as a provider, we don't need to pass data using this constructor anymore.
            // We can use the provider for all the things we need.

            // id: loadedProducts[i].id,
            // imageUrl: loadedProducts[i].imageUrl,
            // title: loadedProducts[i].title,
            ),
      ),
    );
  }
}

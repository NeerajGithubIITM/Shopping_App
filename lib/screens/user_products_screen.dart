import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edit_product_screen.dart';
import '../providers/products.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/user_product_item.dart';

class UserProductsScreen extends StatelessWidget {
  static const routeName = '/user-products';

  Future<void> _refreshProducts(BuildContext ctx) async {
    // async makes a func return a future
    await Provider.of<Products>(ctx, listen: false)
        .fetchProducts(filterByUser: true);
    // The aim is to tell the refresh progress indicator to dismiss the refresh action once the product loading is done
  }

  @override
  Widget build(BuildContext context) {
    // final productsData = Provider.of<Products>(context); // Using FutureBuilder(), so use Consumer()
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(EditProductScreen.routeName);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _refreshProducts(context),
        builder: (ctx, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: () => _refreshProducts(context),
                    child: Consumer<Products>(
                      builder: (ctx, productsData, _) => Padding(
                        padding: EdgeInsets.all(10),
                        child: ListView.builder(
                          itemCount: productsData.items.length,
                          itemBuilder: (_, index) => Column(
                            children: <Widget>[
                              UserProductItem(
                                productsData.items[index]
                                    .id, // required for editing product
                                productsData.items[index].title,
                                productsData.items[index].imageUrl,
                              ),
                              Divider(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
      drawer: DrawerWidget(),
    );
  }
}

// Why the FutureBuilder() here ?
// At first, the products displayed in the overview screen and this screen were the same
// With the feature of filtering products by user coming in, they are now different product lists! (this one is filtered by user)
// But since we don't load products (call fetchProducts()) in this screen when it is rendered (we only call it on refreshing), all the products are displayed at first (unfiltered)
// So, we need to load the products in the beginning in this screen too just like overview screen (but with fiterByUser: true)
// We could convert this to a StatefulWidget (to override and use some initialising function) --> inefficient state management
// Or, as we saw in orders_screen.dart, we could use FutureBuilder() and Consumer()

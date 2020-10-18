import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/cart_screen.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/products_grid.dart';
import '../widgets/badge.dart';
import '../providers/cart.dart';
import '../providers/products.dart';

enum FilterOptions {
  Favorite,
  All,
}

class ProductsOverviewScreen extends StatefulWidget {
  @override
  _ProductsOverviewScreenState createState() => _ProductsOverviewScreenState();
}

class _ProductsOverviewScreenState extends State<ProductsOverviewScreen> {
  var showOnlyFav = false;
  var _isLoading = false;

  @override
  void initState() {
    // Provider.of<Products>(context).fetchProducts(); // Won't work, you know why
    // But note, setting listen to false will work in this case even in initState

    // So, the workaroung here is to use didChangeDependencies.
    // Or..... Use a hack inside initState() itself...

    Future.delayed(Duration.zero).then((_) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<Products>(context, listen: false).fetchProducts().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    });
    // This will work because even though .then() is executed after a zero delay, flutter orders these operations differently from doing it directly without the Future
    // .then() will now execute after the context has been initialized for the widget.
    // Note, this hack would work for any of the previous cases also.
    // And again, didChangeDependencies is always another viable option.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Shop'),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: (FilterOptions selectedValue) {
              setState(() {
                if (selectedValue == FilterOptions.Favorite) {
                  showOnlyFav = true;
                }
                if (selectedValue == FilterOptions.All) {
                  showOnlyFav = false;
                }
              });
            },
            icon: Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                  child: Text('Show only Favorites'),
                  value: FilterOptions.Favorite),
              PopupMenuItem(
                  child: Text('Show all Products'), value: FilterOptions.All),
            ],
          ),
          Consumer<Cart>(
            builder: (_, cart, ch) => Badge(
              child: ch,
              value: cart.itemCount.toString(),
            ),
            child: IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.of(context).pushNamed(CartScreen.routeName);
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ProductsGrid(showOnlyFav),
      drawer: DrawerWidget(),
    );
  }
}

// This widget was made stateful and bool showOnlyFav was passed to ProductGrid() why??
// Though the favorite/non-favorite feature is app wide, the feature of showing only the favorites or showing all products is related to this screen only.
// If we used to a provider and sent data from there based on isFavorite or not, it would work but it would make it an app wide filter.
// Even on other screens, only the favorite products would show up. But that feature must be restricted to this screen only. So manage that state in this widget itself

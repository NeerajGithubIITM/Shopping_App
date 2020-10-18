import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/product_details_screen.dart';
import './screens/products_overview_screen.dart';
import './screens/cart_screen.dart';
import './screens/orders_screen.dart';
import './screens/user_products_screen.dart';
import './screens/edit_product_screen.dart';
import './screens/auth_screen.dart';
import './screens/splash_screen.dart';
import './providers/products.dart';
import './providers/cart.dart';
import './providers/orders.dart';
import './providers/auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Allows us to group multiple providers together
      providers: [
        ChangeNotifierProvider(
          create: (_) => Auth(),
        ),

        // ChangeNotifierProvider(
        //   create: (_) => Products(),
        // ),
        // Had to shift to ProxyProvider to facilitate efficient tranfer of the token from Auth() to the Provider()

        // ignore: missing_required_param
        ChangeNotifierProxyProvider<Auth, Products>(
          // In versions below 4.0.0, it is again builder. For all those above, it is update (and create for the normal provider as we know)
          update: (ctx, authObject, previousProducts) => Products(
              authObject.token,
              authObject.userId,
              previousProducts == null ? [] : previousProducts.items),
        ),
        // This provider rebuilds whenever Auth() changes

        ChangeNotifierProvider(
          create: (_) => Cart(),
        ),

        // ignore: missing_required_param
        ChangeNotifierProxyProvider<Auth, Orders>(
          // In versions below 4.0.0, it is again builder. For all those above, it is update (and create for the normal provider as we know)
          update: (ctx, authObject, previousOrders) => Orders(
              authObject.token,
              authObject.userId,
              previousOrders == null ? [] : previousOrders.orders),
        ),
      ], // create: is only for providers version 4.0.0 or above. For versions before that it is (builder: ));

      child: Consumer<Auth>(
        builder: (ctx, authData, _) => MaterialApp(
          // This child can tap into all the above providers.
          title: 'MyShop',
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
            accentColor: Color.fromRGBO(40, 0, 65, 1),
            fontFamily: 'Lato',
          ),
          home: authData.isAuth
              ? ProductsOverviewScreen()
              : FutureBuilder(
                  future: authData.tryAutoLogin(),
                  builder: (ctx, authResultSnapshot) =>
                      authResultSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? SplashScreen()
                          : AuthScreen(),
                ),
          routes: {
            ProductDetailsScreen.routeName: (ctx) => ProductDetailsScreen(),
            CartScreen.routeName: (ctx) => CartScreen(),
            OrdersScreen.routeName: (ctx) => OrdersScreen(),
            UserProductsScreen.routeName: (ctx) => UserProductsScreen(),
            EditProductScreen.routeName: (ctx) => EditProductScreen(),
          },
        ),
      ),
    );
  }
}

// For cases like these where the value (Products()) doesn't require the context (_), we can use an alternative construtor.
// ChangeNotifierProvider.value(value: Products(), child: MaterialApp() ...)
// Actually, it is preferable to use .value() approach whenever possible, especially in cases where a new provider is created for each list object in a loop (like in products_grid.dart),
// to eliminate the bugs create: might cause due to the way the widgets are recycled. (See more).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders.dart';
import '../widgets/order_item_widget.dart';
import '../widgets/drawer_widget.dart';

// This was converted to a Stateful Widget to implement fetchAndSetOrders(). But went back to a StatelessWidget when FutureBuilder() was introduced.
class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders-screen';

  
  // @override
  // void initState() {
  //   Future.delayed(Duration.zero).then((_) async {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     await Provider.of<Orders>(context, listen: false).fetchAndSetOrders();
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   });
  //   super.initState();
  // }

  // Note: 2 points
  // If we do use listen false for the listener in initState() we don't even need to use the Future.delayed() hack. It will work just fine in intState, even tho there is a context sitting there
  // Another, we had converted this into a StatefulWidget just to be able to use initState and load the data on rendering the screen
  // We need a place in our widget from where we can call fetchAndSetOrders() just once to load the data.
  // And the alterative is FutureBuilder() widget. (and use Stateless widget onli)

  @override
  Widget build(BuildContext context) {
    // final orderData = Provider.of<Orders>(context);
    // Using this listening method on top will result in an infinite loop
    // The above statement causes build to run, and the listener for fetchAndSetOrders() runs build again and this repeats.
    // So, we need to simply wrap that part of the tree which requires the orderData from the provider in a consumer widget.

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
      ),
      body: FutureBuilder(
          future:
              Provider.of<Orders>(context, listen: false).fetchAndSetOrders(),
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              if (dataSnapshot.error != null) {
                // error handling here
                return Center(child: Text('Error happnd'));
              } else {
                return Consumer<Orders>(
                  builder: (ctx, orderData, _) => ListView.builder(
                    itemCount: orderData.orders.length,
                    itemBuilder: (ctx, index) =>
                        OrderItemWidget(orderData.orders[index]),
                  ),
                );
              }
            }
          }),
      drawer: DrawerWidget(),
    );
  }
}

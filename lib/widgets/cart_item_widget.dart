import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart.dart';

class CartItemWidget extends StatelessWidget {
  final String cartItemId;
  final String productId;
  final double price;
  final int quantity;
  final String title;

  CartItemWidget(
      {this.price, this.quantity, this.title, this.cartItemId, this.productId});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cartItemId),
      background: Container(
        color: Theme.of(context).errorColor,
        // The background is displayed once swiping begins.
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 40,
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
      ),
      direction:
          DismissDirection.endToStart, // Alllows only right to left swipe
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Are you sure??'),
            content: Text('Do you want to remove the item from your cart?'),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                // With this the show dialogue will return false and dismiss is not confirmed.
                child: Text('No'),
              ),
              FlatButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                // With this the show dialogue will return true and dismiss is confirmed.
                child: Text('Yes'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        Provider.of<Cart>(context, listen: false).removeItem(productId);
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).accentColor,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: FittedBox(
                  child: Text(
                    'Rs ${price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            title: Text(title),
            subtitle: Text('Total: Rs ${(price * quantity).toStringAsFixed(2)}'),
            trailing: Text('x $quantity'),
          ),
        ),
      ),
    );
  }
}

import 'package:siparis/models/company.dart';
import 'package:siparis/models/product.dart';

enum CustomerOrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
}

class CustomerOrderItem {
  final Product product;
  final int quantity;

  CustomerOrderItem({
    required this.product,
    required this.quantity,
  });
}

class CustomerOrder {
  final String id;
  final Company company;
  final List<CustomerOrderItem> items;
  final DateTime orderDate;
  final CustomerOrderStatus status;
  final double totalAmount;

  CustomerOrder({
    required this.id,
    required this.company,
    required this.items,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
  });
}

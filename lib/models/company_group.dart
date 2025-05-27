import 'package:siparis/models/cart_item.dart';

class CompanyGroup {
  final String companyId;
  final String companyName;
  final List<CartItem> items;

  CompanyGroup({
    required this.companyId,
    required this.companyName,
    required this.items,
  });
}

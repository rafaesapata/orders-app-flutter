import 'package:flutter/foundation.dart';
import '../../core/services/orders_service.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';

class OrdersProvider extends ChangeNotifier {
  final OrdersService _ordersService = OrdersService();
  
  List<Order> _orders = [];
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  Order? _selectedOrder;

  // Getters
  List<Order> get orders => _orders;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get selectedOrder => _selectedOrder;

  // Filtered orders
  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> getRecentOrders({int limit = 10}) {
    final sortedOrders = List<Order>.from(_orders);
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOrders.take(limit).toList();
  }

  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      _orders = await _ordersService.getOrders();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar pedidos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _products = await _ordersService.getProducts();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar produtos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createOrder({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required List<OrderItem> items,
    String? notes,
    String? deliveryAddress,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newOrder = await _ordersService.createOrder(
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        items: items,
        notes: notes,
        deliveryAddress: deliveryAddress,
      );

      _orders.insert(0, newOrder);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao criar pedido: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedOrder = await _ordersService.updateOrderStatus(orderId, newStatus);
      
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        
        // Atualiza o pedido selecionado se for o mesmo
        if (_selectedOrder?.id == orderId) {
          _selectedOrder = updatedOrder;
        }
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Erro ao atualizar status do pedido: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      await _ordersService.deleteOrder(orderId);
      _orders.removeWhere((order) => order.id == orderId);
      
      // Limpa o pedido selecionado se for o mesmo que foi deletado
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao deletar pedido: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectOrder(Order order) {
    _selectedOrder = order;
    notifyListeners();
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  List<String> getProductCategories() {
    final categories = _products.map((product) => product.category).toSet().toList();
    categories.sort();
    return categories;
  }

  double getTotalRevenue() {
    return _orders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  int getTotalOrdersCount() {
    return _orders.length;
  }

  int getPendingOrdersCount() {
    return _orders.where((order) => order.status == OrderStatus.pending).length;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  Future<void> refreshData() async {
    await Future.wait([
      loadOrders(),
      loadProducts(),
    ]);
  }
}


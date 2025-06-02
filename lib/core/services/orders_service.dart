import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/product.dart';

class OrdersService {
  static const String _ordersKey = 'orders_data';
  static const String _productsKey = 'products_data';
  final _uuid = const Uuid();

  // Produtos de exemplo para demonstração
  static final List<Product> _sampleProducts = [
    Product(
      id: '1',
      name: 'Hambúrguer Clássico',
      description: 'Hambúrguer com carne, queijo, alface e tomate',
      price: 25.90,
      category: 'Hambúrgueres',
      stockQuantity: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Product(
      id: '2',
      name: 'Pizza Margherita',
      description: 'Pizza com molho de tomate, mussarela e manjericão',
      price: 35.00,
      category: 'Pizzas',
      stockQuantity: 25,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Product(
      id: '3',
      name: 'Refrigerante Cola',
      description: 'Refrigerante de cola 350ml',
      price: 5.50,
      category: 'Bebidas',
      stockQuantity: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Product(
      id: '4',
      name: 'Batata Frita',
      description: 'Porção de batata frita crocante',
      price: 12.00,
      category: 'Acompanhamentos',
      stockQuantity: 75,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Product(
      id: '5',
      name: 'Salada Caesar',
      description: 'Salada com alface, croutons, parmesão e molho caesar',
      price: 18.50,
      category: 'Saladas',
      stockQuantity: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<List<Order>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simula delay de rede
    
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString(_ordersKey);
    
    if (ordersJson == null) {
      // Retorna pedidos de exemplo na primeira execução
      final sampleOrders = _generateSampleOrders();
      await _saveOrders(sampleOrders);
      return sampleOrders;
    }
    
    try {
      final ordersList = jsonDecode(ordersJson) as List<dynamic>;
      return ordersList
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Order?> getOrderById(String id) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Order> createOrder({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required List<OrderItem> items,
    String? notes,
    String? deliveryAddress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simula delay de rede

    if (items.isEmpty) {
      throw Exception('Pedido deve conter pelo menos um item');
    }

    final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final tax = subtotal * 0.1; // 10% de taxa
    const discount = 0.0;
    final total = subtotal + tax - discount;

    final order = Order(
      id: _uuid.v4(),
      customerId: _uuid.v4(),
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      createdAt: DateTime.now(),
      status: OrderStatus.pending,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      notes: notes,
      deliveryAddress: deliveryAddress,
    );

    final orders = await getOrders();
    orders.insert(0, order); // Adiciona no início da lista
    await _saveOrders(orders);

    return order;
  }

  Future<Order> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final orders = await getOrders();
    final orderIndex = orders.indexWhere((order) => order.id == orderId);
    
    if (orderIndex == -1) {
      throw Exception('Pedido não encontrado');
    }

    final updatedOrder = orders[orderIndex].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    orders[orderIndex] = updatedOrder;
    await _saveOrders(orders);

    return updatedOrder;
  }

  Future<void> deleteOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final orders = await getOrders();
    orders.removeWhere((order) => order.id == orderId);
    await _saveOrders(orders);
  }

  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);
    
    if (productsJson == null) {
      await _saveProducts(_sampleProducts);
      return _sampleProducts;
    }
    
    try {
      final productsList = jsonDecode(productsJson) as List<dynamic>;
      return productsList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return _sampleProducts;
    }
  }

  Future<List<String>> getProductCategories() async {
    final products = await getProducts();
    final categories = products.map((product) => product.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<void> _saveOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = jsonEncode(orders.map((order) => order.toJson()).toList());
    await prefs.setString(_ordersKey, ordersJson);
  }

  Future<void> _saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = jsonEncode(products.map((product) => product.toJson()).toList());
    await prefs.setString(_productsKey, productsJson);
  }

  List<Order> _generateSampleOrders() {
    final now = DateTime.now();
    return [
      Order(
        id: _uuid.v4(),
        customerId: 'customer1',
        customerName: 'João Silva',
        customerPhone: '(11) 99999-1234',
        customerEmail: 'joao@email.com',
        createdAt: now.subtract(const Duration(hours: 2)),
        status: OrderStatus.preparing,
        items: [
          OrderItem(
            id: _uuid.v4(),
            productId: '1',
            productName: 'Hambúrguer Clássico',
            quantity: 2,
            unitPrice: 25.90,
            total: 51.80,
          ),
          OrderItem(
            id: _uuid.v4(),
            productId: '3',
            productName: 'Refrigerante Cola',
            quantity: 2,
            unitPrice: 5.50,
            total: 11.00,
          ),
        ],
        subtotal: 62.80,
        tax: 6.28,
        discount: 0.0,
        total: 69.08,
        deliveryAddress: 'Rua das Flores, 123 - Centro',
      ),
      Order(
        id: _uuid.v4(),
        customerId: 'customer2',
        customerName: 'Maria Santos',
        customerPhone: '(11) 88888-5678',
        createdAt: now.subtract(const Duration(hours: 5)),
        status: OrderStatus.delivered,
        items: [
          OrderItem(
            id: _uuid.v4(),
            productId: '2',
            productName: 'Pizza Margherita',
            quantity: 1,
            unitPrice: 35.00,
            total: 35.00,
          ),
        ],
        subtotal: 35.00,
        tax: 3.50,
        discount: 0.0,
        total: 38.50,
      ),
      Order(
        id: _uuid.v4(),
        customerId: 'customer3',
        customerName: 'Pedro Costa',
        customerPhone: '(11) 77777-9012',
        createdAt: now.subtract(const Duration(days: 1)),
        status: OrderStatus.pending,
        items: [
          OrderItem(
            id: _uuid.v4(),
            productId: '5',
            productName: 'Salada Caesar',
            quantity: 1,
            unitPrice: 18.50,
            total: 18.50,
          ),
          OrderItem(
            id: _uuid.v4(),
            productId: '4',
            productName: 'Batata Frita',
            quantity: 1,
            unitPrice: 12.00,
            total: 12.00,
          ),
        ],
        subtotal: 30.50,
        tax: 3.05,
        discount: 0.0,
        total: 33.55,
        notes: 'Sem cebola na salada',
      ),
    ];
  }
}


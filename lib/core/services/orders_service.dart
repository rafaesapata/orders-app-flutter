import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';

class OrdersService {
  static final OrdersService _instance = OrdersService._internal();
  factory OrdersService() => _instance;
  OrdersService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Busca todos os pedidos
  Future<List<Order>> getOrders({
    int page = 1,
    int limit = 50,
    OrderStatus? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status.value;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final endpoint = '${ApiConfig.ordersEndpoint}?$queryString';
      final response = await _apiClient.get(endpoint);

      final ordersData = response['data'] as List<dynamic>? ?? response['orders'] as List<dynamic>? ?? [];
      return ordersData.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar pedidos: $e');
    }
  }

  /// Busca um pedido específico por ID
  Future<Order?> getOrderById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.ordersEndpoint}/$id');
      return Order.fromJson(response['data'] ?? response);
    } catch (e) {
      return null;
    }
  }

  /// Cria um novo pedido
  Future<Order> createOrder({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required List<OrderItem> items,
    String? notes,
    String? deliveryAddress,
  }) async {
    try {
      final orderData = {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_email': customerEmail,
        'items': items.map((item) => {
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
          'notes': item.notes,
        }).toList(),
        'notes': notes,
        'delivery_address': deliveryAddress,
        'status': OrderStatus.pending.value,
        'total': items.fold(0.0, (sum, item) => sum + item.total),
      };

      final response = await _apiClient.post(ApiConfig.ordersEndpoint, data: orderData);
      return Order.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Erro ao criar pedido: $e');
    }
  }

  /// Atualiza um pedido existente
  Future<Order> updateOrder(String id, {
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    List<OrderItem>? items,
    String? notes,
    String? deliveryAddress,
    OrderStatus? status,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (customerName != null) updateData['customer_name'] = customerName;
      if (customerPhone != null) updateData['customer_phone'] = customerPhone;
      if (customerEmail != null) updateData['customer_email'] = customerEmail;
      if (notes != null) updateData['notes'] = notes;
      if (deliveryAddress != null) updateData['delivery_address'] = deliveryAddress;
      if (status != null) updateData['status'] = status.value;

      if (items != null) {
        updateData['items'] = items.map((item) => {
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
          'notes': item.notes,
        }).toList();
        updateData['total'] = items.fold(0.0, (sum, item) => sum + item.total);
      }

      final response = await _apiClient.put('${ApiConfig.ordersEndpoint}/$id', data: updateData);
      return Order.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Erro ao atualizar pedido: $e');
    }
  }

  /// Atualiza apenas o status de um pedido
  Future<bool> updateOrderStatus(String id, OrderStatus status) async {
    try {
      await _apiClient.put(
        '${ApiConfig.ordersEndpoint}/$id/status',
        data: {'status': status.value},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Exclui um pedido
  Future<bool> deleteOrder(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.ordersEndpoint}/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Busca produtos disponíveis
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 100,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final endpoint = '${ApiConfig.productsEndpoint}?$queryString';
      final response = await _apiClient.get(endpoint);

      final productsData = response['data'] as List<dynamic>? ?? response['products'] as List<dynamic>? ?? [];
      return productsData.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      // Fallback para produtos locais se a API não estiver disponível
      return _getFallbackProducts();
    }
  }

  /// Busca estatísticas de pedidos
  Future<Map<String, dynamic>> getOrdersStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.ordersEndpoint}/stats');
      return response['data'] ?? response;
    } catch (e) {
      // Retorna estatísticas vazias em caso de erro
      return {
        'total_orders': 0,
        'pending_orders': 0,
        'completed_orders': 0,
        'total_revenue': 0.0,
        'average_order_value': 0.0,
      };
    }
  }

  /// Produtos de fallback caso a API não esteja disponível
  List<Product> _getFallbackProducts() {
    return [
      Product(
        id: '1',
        name: 'Hambúrguer Clássico',
        description: 'Hambúrguer com carne, queijo, alface e tomate',
        price: 25.90,
        category: 'Hambúrgueres',
        isAvailable: true,
        image: null,
      ),
      Product(
        id: '2',
        name: 'Pizza Margherita',
        description: 'Pizza com molho de tomate, mussarela e manjericão',
        price: 35.00,
        category: 'Pizzas',
        isAvailable: true,
        image: null,
      ),
      Product(
        id: '3',
        name: 'Refrigerante Lata',
        description: 'Refrigerante gelado 350ml',
        price: 5.50,
        category: 'Bebidas',
        isAvailable: true,
        image: null,
      ),
      Product(
        id: '4',
        name: 'Batata Frita',
        description: 'Porção de batata frita crocante',
        price: 12.00,
        category: 'Acompanhamentos',
        isAvailable: true,
        image: null,
      ),
      Product(
        id: '5',
        name: 'Salada Caesar',
        description: 'Salada com alface, croutons, parmesão e molho caesar',
        price: 18.50,
        category: 'Saladas',
        isAvailable: true,
        image: null,
      ),
    ];
  }
}


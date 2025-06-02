import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';

class OrderFormPage extends StatefulWidget {
  final String? orderId;

  const OrderFormPage({super.key, this.orderId});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryAddressController = TextEditingController();

  List<OrderItem> _orderItems = [];
  bool get isEditing => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _orderItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _tax {
    return _subtotal * 0.1; // 10% de taxa
  }

  double get _total {
    return _subtotal + _tax;
  }

  void _addProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => _ProductQuantityDialog(
        product: product,
        onAdd: (quantity, notes) {
          final item = OrderItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: product.id,
            productName: product.name,
            productImage: product.image,
            quantity: quantity,
            unitPrice: product.price,
            total: product.price * quantity,
            notes: notes.isEmpty ? null : notes,
          );

          setState(() {
            // Verifica se o produto já existe no pedido
            final existingIndex = _orderItems.indexWhere(
              (item) => item.productId == product.id,
            );

            if (existingIndex != -1) {
              // Atualiza a quantidade se o produto já existe
              final existingItem = _orderItems[existingIndex];
              _orderItems[existingIndex] = existingItem.copyWith(
                quantity: existingItem.quantity + quantity,
                total: (existingItem.quantity + quantity) * product.price,
              );
            } else {
              // Adiciona novo item
              _orderItems.add(item);
            }
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }

    setState(() {
      final item = _orderItems[index];
      _orderItems[index] = item.copyWith(
        quantity: newQuantity,
        total: newQuantity * item.unitPrice,
      );
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um item ao pedido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ordersProvider = context.read<OrdersProvider>();
    final success = await ordersProvider.createOrder(
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isEmpty 
          ? null 
          : _customerPhoneController.text.trim(),
      customerEmail: _customerEmailController.text.trim().isEmpty 
          ? null 
          : _customerEmailController.text.trim(),
      items: _orderItems,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      deliveryAddress: _deliveryAddressController.text.trim().isEmpty 
          ? null 
          : _deliveryAddressController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Pedido' : 'Novo Pedido'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informações do Cliente
                        _buildSectionHeader('Informações do Cliente'),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _customerNameController,
                          label: 'Nome do Cliente *',
                          hintText: 'Digite o nome do cliente',
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nome do cliente é obrigatório';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _customerPhoneController,
                                label: 'Telefone',
                                hintText: '(11) 99999-9999',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _customerEmailController,
                                label: 'Email',
                                hintText: 'cliente@email.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _deliveryAddressController,
                          label: 'Endereço de Entrega',
                          hintText: 'Digite o endereço completo',
                          prefixIcon: Icons.location_on,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),

                        // Produtos Disponíveis
                        _buildSectionHeader('Adicionar Produtos'),
                        const SizedBox(height: 16),

                        if (ordersProvider.products.isEmpty)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ordersProvider.products.length,
                              itemBuilder: (context, index) {
                                final product = ordersProvider.products[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Itens do Pedido
                        _buildSectionHeader('Itens do Pedido'),
                        const SizedBox(height: 16),

                        if (_orderItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum item adicionado',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Selecione produtos acima para adicionar ao pedido',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(_orderItems.length, (index) {
                            final item = _orderItems[index];
                            return _buildOrderItemCard(item, index);
                          }),

                        const SizedBox(height: 24),

                        // Observações
                        CustomTextField(
                          controller: _notesController,
                          label: 'Observações',
                          hintText: 'Observações adicionais sobre o pedido',
                          prefixIcon: Icons.note,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Resumo e Botão de Salvar
                if (_orderItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('R\$ ${_subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Taxa (10%):'),
                            Text('R\$ ${_tax.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'R\$ ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: isEditing ? 'Atualizar Pedido' : 'Criar Pedido',
                          onPressed: ordersProvider.isLoading ? null : _saveOrder,
                          isLoading: ordersProvider.isLoading,
                        ),
                      ],
                    ),
                  ),

                // Mensagem de erro
                if (ordersProvider.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red[50],
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ordersProvider.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: ordersProvider.clearError,
                          color: Colors.red[700],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => _addProduct(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'R\$ ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fastfood,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'R\$ ${item.unitPrice.toStringAsFixed(2)} cada',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (item.notes != null)
                    Text(
                      'Obs: ${item.notes}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _updateItemQuantity(index, item.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductQuantityDialog extends StatefulWidget {
  final Product product;
  final Function(int quantity, String notes) onAdd;

  const _ProductQuantityDialog({
    required this.product,
    required this.onAdd,
  });

  @override
  State<_ProductQuantityDialog> createState() => _ProductQuantityDialogState();
}

class _ProductQuantityDialogState extends State<_ProductQuantityDialog> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Preço: R\$ ${widget.product.price.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Ex: Sem cebola, bem passado...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Total: R\$ ${(widget.product.price * _quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_quantity, _notesController.text);
            Navigator.pop(context);
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/merch_item.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class MerchScreen extends StatefulWidget {
  const MerchScreen({super.key, required this.dataService});

  final DataService dataService;

  @override
  State<MerchScreen> createState() => _MerchScreenState();
}

class _MerchScreenState extends State<MerchScreen> {
  final Map<String, String> _selectedSizes = {};

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  Future<void> _addToCart(MerchItem product) async {
    final size = _selectedSizes[product.id] ?? product.sizes.first;
    try {
      await widget.dataService.addToCart(product.id, size);
      if (mounted) {
        setState(() {});
        _showMessage('${product.name} // AGREGADO AL CARRITO');
      }
    } catch (error) {
      if (mounted) _showMessage('NO SE PUDO AGREGAR: $error');
    }
  }

  Future<void> _openCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          final items = widget.dataService.cartItems;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '> CARRITO DE LA PECERA',
                            style: TextStyle(
                              color: TerminalTheme.red,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (items.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'EL CARRITO ESTÁ VACÍO',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final product = widget.dataService.merch.firstWhere(
                              (entry) => entry.id == item.productId,
                            );
                            final otherSizesQuantity = items
                                .where(
                                  (entry) =>
                                      entry.productId == item.productId &&
                                      entry.size != item.size,
                                )
                                .fold(
                                  0,
                                  (total, entry) => total + entry.quantity,
                                );
                            return _CartRow(
                              item: item,
                              product: product,
                              maxQuantity: product.stock - otherSizesQuantity,
                              onQuantityChanged: (quantity) async {
                                try {
                                  await widget.dataService.setCartQuantity(
                                    item,
                                    quantity,
                                  );
                                  updateSheet(() {});
                                  if (mounted) setState(() {});
                                } catch (error) {
                                  _showMessage('NO SE PUDO ACTUALIZAR: $error');
                                }
                              },
                            );
                          },
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL'),
                        Text(
                          '\$${widget.dataService.cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: TerminalTheme.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PEDIDO PERSISTENTE EN ESTE DISPOSITIVO',
                      style: TextStyle(color: Colors.white54, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.dataService.merch;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 3 : 2;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '> MERCH OFICIAL',
                        style: TextStyle(
                          color: TerminalTheme.red,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openCart,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: Text('CARRITO (${widget.dataService.cartCount})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TerminalTheme.red,
                        side: BorderSide(
                          color: TerminalTheme.red.withValues(alpha: 0.5),
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columns == 2 ? 0.53 : 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MerchCard(
                    product: products[index],
                    selectedSize:
                        _selectedSizes[products[index].id] ??
                        products[index].sizes.first,
                    onSizeChanged: (size) => setState(
                      () => _selectedSizes[products[index].id] = size,
                    ),
                    onAdd: () => _addToCart(products[index]),
                  ),
                  childCount: products.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MerchCard extends StatelessWidget {
  const _MerchCard({
    required this.product,
    required this.selectedSize,
    required this.onSizeChanged,
    required this.onAdd,
  });

  final MerchItem product;
  final String selectedSize;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return TerminalPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Image.asset(
              product.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: TerminalTheme.red,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 9),
          ),
          const SizedBox(height: 5),
          Text(
            '\$${product.price.toStringAsFixed(2)} MXN',
            style: const TextStyle(color: TerminalTheme.red, fontSize: 12),
          ),
          Text(
            'STOCK: ${product.stock}',
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: selectedSize,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'TALLA',
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            ),
            dropdownColor: Colors.black,
            items: product.sizes
                .map((size) => DropdownMenuItem(value: size, child: Text(size)))
                .toList(),
            onChanged: (size) {
              if (size != null) onSizeChanged(size);
            },
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: product.stock > 0 ? onAdd : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: TerminalTheme.red,
                disabledBackgroundColor: Colors.white12,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'AGREGAR',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.product,
    required this.maxQuantity,
    required this.onQuantityChanged,
  });

  final CartItem item;
  final MerchItem product;
  final int maxQuantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  'TALLA ${item.size} // \$${(product.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: TerminalTheme.red,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar una unidad',
            onPressed: () => onQuantityChanged(item.quantity - 1),
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('${item.quantity}'),
          IconButton(
            tooltip: 'Agregar una unidad',
            onPressed: item.quantity < maxQuantity
                ? () => onQuantityChanged(item.quantity + 1)
                : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

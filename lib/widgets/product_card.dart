import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.nombre,
    required this.marca,
    required this.sku,
    required this.precio,
    required this.stock,
    required this.lowStock,
    this.imagen,
    this.onAdd,
    this.onEdit,
    this.onStock,
  });

  final String nombre;
  final String marca;
  final String sku;
  final String precio;
  final String stock;
  final bool lowStock;
  final String? imagen;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (imagen != null && imagen!.isNotEmpty)
                      ? Image.network(
                          imagen!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.oil_barrel,
                              size: 42,
                              color: Color(0xFF4C7ED9),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.oil_barrel,
                            size: 42,
                            color: Color(0xFF4C7ED9),
                          ),
                        ),
                ),
                if (lowStock)
                  Positioned(
                    right: 18,
                    top: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'STOCK BAJO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2540),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Marca: $marca • SKU: $sku',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A7788),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE3E8EF)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      stock,
                      style: TextStyle(
                        color: lowStock
                            ? const Color(0xFFDF2E2E)
                            : const Color(0xFF0A2540),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      precio,
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (onEdit != null || onStock != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (onEdit != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Editar'),
                          ),
                        ),
                      if (onEdit != null && onStock != null)
                        const SizedBox(width: 8),
                      if (onStock != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onStock,
                            icon: const Icon(Icons.add_box_outlined, size: 16),
                            label: const Text('+ Stock'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else if (onAdd != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

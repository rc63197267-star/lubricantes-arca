import 'package:flutter/material.dart';

class SaleProductCard extends StatelessWidget {
  const SaleProductCard({
    super.key,
    required this.nombre,
    required this.marca,
    required this.precio,
    required this.stock,
    required this.cantidad,
    required this.lowStock,
    required this.onAdd,
    required this.onRemove,
    this.imagen,
  });

  final String nombre;
  final String marca;
  final String precio;
  final int stock;
  final int cantidad;
  final bool lowStock;
  final String? imagen;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final agotado = stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cantidad > 0
              ? const Color(0xFF3B82F6)
              : const Color(0xFFE3E8EF),
          width: cantidad > 0 ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A2540),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (imagen != null && imagen!.isNotEmpty)
                        ? Image.network(
                            imagen!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const _ProductFallback(),
                          )
                        : const _ProductFallback(),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _StockBadge(agotado: agotado, lowStock: lowStock),
                ),
                if (cantidad > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2540),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0A2540),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  marca,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6A7788),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stock: $stock',
                        style: TextStyle(
                          color: agotado
                              ? const Color(0xFFD14343)
                              : lowStock
                              ? const Color(0xFFD97706)
                              : const Color(0xFF228B57),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      precio,
                      style: const TextStyle(
                        color: Color(0xFF1665D8),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onPressed: cantidad > 0 ? onRemove : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: Color(0xFFD6DEE9)),
                          ),
                        ),
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                            color: Color(0xFF0A2540),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      primary: true,
                      onPressed: agotado || cantidad >= stock ? null : onAdd,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.oil_barrel_rounded, size: 46, color: Color(0xFF4C7ED9)),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.agotado, required this.lowStock});

  final bool agotado;
  final bool lowStock;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color background;
    final Color foreground;

    if (agotado) {
      text = 'Agotado';
      background = const Color(0xFFFFE4E6);
      foreground = const Color(0xFFBE123C);
    } else if (lowStock) {
      text = 'Stock bajo';
      background = const Color(0xFFFFF1C2);
      foreground = const Color(0xFFB45309);
    } else {
      text = 'Disponible';
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF15803D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 36,
      child: Material(
        color: onPressed == null
            ? const Color(0xFFF0F3F7)
            : primary
            ? const Color(0xFF1677F2)
            : const Color(0xFFF4F7FB),
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null
                ? const Color(0xFFA8B2C1)
                : primary
                ? Colors.white
                : const Color(0xFF0A2540),
          ),
        ),
      ),
    );
  }
}

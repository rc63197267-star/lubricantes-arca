import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.trend,
    required this.icono,
    required this.accento,
    required this.positivo,
  });

  final String titulo;
  final String valor;
  final String trend;
  final IconData icono;
  final Color accento;
  final bool positivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A7788),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accento,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: const Color(0xFF0A2540), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A2540),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                positivo ? Icons.trending_up : Icons.access_time_filled,
                color: positivo ? Colors.green : const Color(0xFF6A7788),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    color: positivo ? Colors.green : const Color(0xFF6A7788),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WarningMetricCard extends StatelessWidget {
  const WarningMetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6E7B6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7D8A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2540),
                    height: 1.3,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: const Color(0xFFB91C1C), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A2540),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5D5D5D)),
          ),
        ],
      ),
    );
  }
}

class Bar extends StatelessWidget {
  const Bar({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF8EB8F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopProductRow extends StatelessWidget {
  const TopProductRow({
    super.key,
    required this.nombre,
    required this.sku,
    required this.ventas,
  });

  final String nombre;
  final String sku;
  final int ventas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Color(0xFF0A2540),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A2540),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sku,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A7788),
                  ),
                ),
              ],
            ),
          ),
          Text(
            ventas.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A2540),
            ),
          ),
        ],
      ),
    );
  }
}

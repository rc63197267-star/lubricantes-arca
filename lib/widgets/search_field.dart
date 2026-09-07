import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, color: Color(0xFF6A7788)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buscar productos, SKUs o marcas...',
              style: TextStyle(color: Color(0xFF6A7788), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

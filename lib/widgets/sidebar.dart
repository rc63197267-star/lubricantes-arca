import 'package:flutter/material.dart';

class NavItem {
  const NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

typedef OnNavSelected = void Function(int index);

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final OnNavSelected onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      color: const Color(0xFF0A2540),
      padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.oil_barrel,
                  color: Color(0xFF0A2540),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lubricantes\nArca',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Panel de administración',
                      style: TextStyle(color: Color(0xFFB7CBEA), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Agregar producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final item = items[index];
                final active = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        onSelect(index);
                        // close drawer on small screens
                        Navigator.maybePop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFDDEBFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: active
                                  ? const Color(0xFF0A2540)
                                  : const Color(0xFFB7CBEA),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: active
                                    ? const Color(0xFF0A2540)
                                    : const Color(0xFFB7CBEA),
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF2A3F5D)),
          const SizedBox(height: 12),
          const SidebarLink(icon: Icons.help_outline, label: 'Soporte'),
          const SizedBox(height: 4),
          const SidebarLink(
            icon: Icons.logout_outlined,
            label: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }
}

class SidebarLink extends StatelessWidget {
  const SidebarLink({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB7CBEA), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB7CBEA),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

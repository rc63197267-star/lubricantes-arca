import 'package:flutter/material.dart';
import '../services/api_client.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  late Future<List<Supplier>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      body: FutureBuilder<List<Supplier>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (c, i) {
              final s = items[i];
              return ListTile(
                title: Text(s.nombre),
                subtitle: Text(
                  'Tel: ${s.telefono ?? '-'} • Correo: ${s.correo ?? '-'} • Dir: ${s.direccion ?? '-'}',
                ),
                trailing: Chip(
                  label: Text(s.estado),
                  backgroundColor: s.estado == 'ACTIVO'
                      ? const Color(0xFFE7F7ED)
                      : const Color(0xFFFEE2E2),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateDialog(),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String telefono = '';
    String correo = '';
    String direccion = '';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo proveedor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onSaved: (v) => nombre = v?.trim() ?? '',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  onSaved: (v) => telefono = v?.trim() ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (v) => correo = v?.trim() ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  onSaved: (v) => direccion = v?.trim() ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(ctx);
                final s = Supplier(
                  id: 0,
                  nombre: nombre,
                  telefono: telefono.isEmpty ? null : telefono,
                  correo: correo.isEmpty ? null : correo,
                  direccion: direccion.isEmpty ? null : direccion,
                );
                try {
                  await createSupplier(s);
                  navigator.pop(true);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error creando proveedor: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _future = fetchSuppliers();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proveedor creado')));
    }
  }
}

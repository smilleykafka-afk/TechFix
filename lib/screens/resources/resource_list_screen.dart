import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/resource_fields.dart';
import '../../core/routes/app_routes.dart';
import '../../models/resource_record.dart';
import '../../services/resource_service.dart';
import '../../widgets/async_content.dart';

class ResourceListScreen extends StatefulWidget {
  final String resource;
  const ResourceListScreen({super.key, required this.resource});
  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final search = TextEditingController();
  String status = '';
  late Future<List<ResourceRecord>> data;
  ResourceService get service => ResourceService(widget.resource);
  @override
  void initState() {
    super.initState();
    data = service.list();
  }

  @override
  void didUpdateWidget(covariant ResourceListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource) {
      search.clear();
      status = '';
      data = service.list();
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reload() =>
      setState(() => data = service.list(search: search.text, status: status));
  Future<void> remove(ResourceRecord row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text(row.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await service.delete(row.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro excluído.')));
        reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(ResourceFields.titles[widget.resource]!),
      actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.goNamed(
        AppRoutes.form,
        pathParameters: {'resource': widget.resource},
      ),
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: search,
            decoration: InputDecoration(
              labelText: 'Buscar',
              suffixIcon: IconButton(
                onPressed: reload,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => reload(),
          ),
        ),
        if (widget.resource == 'ordens')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Filtrar status'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos')),
                for (final s in ApiConfig.statuses)
                  DropdownMenuItem(
                    value: s,
                    child: Text(ApiConfig.statusLabels[s]!),
                  ),
              ],
              onChanged: (v) {
                status = v!;
                reload();
              },
            ),
          ),
        Expanded(
          child: AsyncContent(
            future: data,
            retry: reload,
            builder: (rows) => rows.isEmpty
                ? const Center(child: Text('Nenhum registro encontrado.'))
                : RefreshIndicator(
                    onRefresh: () async {
                      reload();
                      await data;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              widget.resource == 'ordens'
                                  ? Icons.build_outlined
                                  : Icons.description_outlined,
                            ),
                          ),
                          title: Text(row.label),
                          subtitle: Text(
                            widget.resource == 'ordens'
                                ? '${ApiConfig.statusLabels[row.values['status']]} · ${row.values['problem']}'
                                : '${row.values['email'] ?? row.values['brand'] ?? row.values['phone'] ?? row.values['sku'] ?? ''}',
                          ),
                          onTap: () => context.goNamed(
                            widget.resource == 'ordens'
                                ? AppRoutes.details
                                : AppRoutes.form,
                            pathParameters: {'resource': widget.resource},
                            queryParameters: {'id': '${row.id}'},
                          ),
                          trailing: IconButton(
                            tooltip: 'Excluir',
                            onPressed: () => remove(row),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

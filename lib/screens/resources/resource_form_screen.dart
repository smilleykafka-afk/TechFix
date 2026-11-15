import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/resource_fields.dart';
import '../../core/utils/validators.dart';
import '../../services/resource_service.dart';
import '../../widgets/async_content.dart';

class ResourceFormScreen extends StatefulWidget {
  final String resource;
  final int? id;
  const ResourceFormScreen({super.key, required this.resource, this.id});
  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final choices = <String, List<DropdownMenuItem<String>>>{};
  late Future<bool> ready = load();
  bool busy = false;
  String? error;
  List<ResourceField> get fields => ResourceFields.fields[widget.resource]!;
  Future<bool> load() async {
    final row = widget.id == null
        ? <String, dynamic>{}
        : (await ResourceService(widget.resource).get(widget.id!)).values;
    if (!mounted) return false;
    for (final field in fields) {
      controllers.putIfAbsent(field.key, () => TextEditingController());
      controllers[field.key]!.text =
          '${row[field.key] ?? (field.numeric ? '0' : '')}';
      if (field.relation != null) {
        final rows = await ResourceService(field.relation!).list();
        if (!mounted) return false;
        choices[field.key] = [
          if (!field.required)
            const DropdownMenuItem(value: '', child: Text('Não atribuído')),
          for (final r in rows)
            DropdownMenuItem(value: '${r.id}', child: Text(r.label)),
        ];
      }
    }
    choices['status'] = [
      for (final s in ApiConfig.statuses)
        DropdownMenuItem(value: s, child: Text(ApiConfig.statusLabels[s]!)),
    ];
    choices['role'] = const [
      DropdownMenuItem(value: 'employee', child: Text('Funcionário')),
      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
    ];
    if (controllers['status']?.text == '') {
      controllers['status']!.text = 'received';
    }
    if (controllers['role']?.text == '') controllers['role']!.text = 'employee';
    return true;
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final values = <String, dynamic>{};
      for (final field in fields) {
        final value = controllers[field.key]!.text.trim();
        if (field.key == 'password' && value.isEmpty && widget.id != null) {
          continue;
        }
        values[field.key] = field.numeric
            ? num.parse(value.replaceAll(',', '.'))
            : field.relation != null
            ? int.tryParse(value)
            : value.isEmpty && !field.required
            ? null
            : value;
      }
      await ResourceService(widget.resource).save(values, id: widget.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro salvo.')));
        context.goNamed(widget.resource);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${widget.id == null ? 'Novo' : 'Editar'} · ${ResourceFields.titles[widget.resource]}',
      ),
      leading: IconButton(
        onPressed: () => context.goNamed(widget.resource),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: AsyncContent(
      future: ready,
      retry: () => setState(() => ready = load()),
      builder: (_) => Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final field in fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: choices.containsKey(field.key)
                    ? DropdownButtonFormField<String>(
                        initialValue:
                            choices[field.key]!.any(
                              (c) => c.value == controllers[field.key]!.text,
                            )
                            ? controllers[field.key]!.text
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: field.label),
                        items: choices[field.key],
                        onChanged: busy
                            ? null
                            : (v) => controllers[field.key]!.text = v ?? '',
                        validator: (v) =>
                            field.required ? Validators.required(v) : null,
                      )
                    : TextFormField(
                        controller: controllers[field.key],
                        enabled: !busy,
                        obscureText: field.key == 'password',
                        keyboardType: field.numeric
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : field.key == 'email'
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        decoration: InputDecoration(labelText: field.label),
                        validator: (v) {
                          if (field.key == 'password') {
                            return widget.id == null || (v?.isNotEmpty ?? false)
                                ? Validators.password(v)
                                : null;
                          }
                          if (field.required &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Campo obrigatório.';
                          }
                          if (field.key == 'email' &&
                              (v?.isNotEmpty ?? false)) {
                            return Validators.email(v);
                          }
                          if (field.numeric) {
                            final n = num.tryParse(
                              (v ?? '').replaceAll(',', '.'),
                            );
                            if (n == null ||
                                !n.isFinite ||
                                n < 0 ||
                                (field.key == 'quantity' && n != n.round())) {
                              return 'Informe um número válido, não negativo.';
                            }
                          }
                          return null;
                        },
                      ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Salvando…' : 'Salvar'),
            ),
          ],
        ),
      ),
    ),
  );
}

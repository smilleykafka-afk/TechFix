class ResourceField {
  final String key, label;
  final bool required, numeric;
  final String? relation;
  const ResourceField(
    this.key,
    this.label, {
    this.required = true,
    this.numeric = false,
    this.relation,
  });
}

abstract final class ResourceFields {
  static const titles = {
    'clientes': 'Clientes',
    'aparelhos': 'Aparelhos',
    'ordens': 'Ordens de serviço',
    'users': 'Funcionários',
    'parts': 'Estoque de peças',
  };
  static const fields = <String, List<ResourceField>>{
    'clientes': [
      ResourceField('name', 'Nome'),
      ResourceField('email', 'E-mail', required: false),
      ResourceField('phone', 'Telefone'),
      ResourceField('address', 'Endereço', required: false),
    ],
    'aparelhos': [
      ResourceField(
        'cliente_id',
        'Cliente (opcional)',
        required: false,
        relation: 'clientes',
      ),
      ResourceField('brand', 'Marca'),
      ResourceField('model', 'Modelo'),
      ResourceField('notes', 'Observações', required: false),
    ],
    'ordens': [
      ResourceField('aparelho_id', 'Aparelho', relation: 'aparelhos'),
      ResourceField(
        'assigned_to',
        'Responsável',
        required: false,
        relation: 'employees',
      ),
      ResourceField('problem', 'Problema relatado'),
      ResourceField('diagnosis', 'Diagnóstico', required: false),
      ResourceField('status', 'Status'),
      ResourceField('price', 'Valor (R\$)', numeric: true),
      ResourceField('notes', 'Observações', required: false),
    ],
    'users': [
      ResourceField('name', 'Nome'),
      ResourceField('email', 'E-mail'),
      ResourceField(
        'password',
        'Senha (vazia mantém a atual)',
        required: false,
      ),
      ResourceField('role', 'Permissão'),
    ],
    'parts': [
      ResourceField('name', 'Nome'),
      ResourceField('sku', 'Código'),
      ResourceField('quantity', 'Quantidade', numeric: true),
      ResourceField('price', 'Preço (R\$)', numeric: true),
    ],
  };
}

abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const statuses = [
    'received',
    'diagnosing',
    'awaiting_parts',
    'repairing',
    'completed',
    'delivered',
    'cancelled',
  ];
  static const statusLabels = {
    'received': 'Recebida',
    'diagnosing': 'Em diagnóstico',
    'awaiting_parts': 'Aguardando peças',
    'repairing': 'Em reparo',
    'completed': 'Concluída',
    'delivered': 'Entregue',
    'cancelled': 'Cancelada',
  };
}

/// API record shared by the metadata-driven resource forms. No UI dependencies.
class ResourceRecord {
  final Map<String, dynamic> values;
  ResourceRecord.fromJson(Map<String, dynamic> json)
    : values = Map.unmodifiable(json);
  int get id => values['id'] as int;
  String get label =>
      '${values['number'] ?? values['name'] ?? values['model'] ?? id}';
  Map<String, dynamic> toJson() => Map.of(values);
}

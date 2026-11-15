import 'package:flutter/material.dart';

class AsyncContent<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T) builder;
  final VoidCallback retry;
  const AsyncContent({
    super.key,
    required this.future,
    required this.builder,
    required this.retry,
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
              FilledButton(
                onPressed: retry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return builder(snapshot.data as T);
    },
  );
}

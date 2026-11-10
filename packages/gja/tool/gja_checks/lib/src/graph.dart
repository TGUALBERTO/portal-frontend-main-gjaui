/// Encontra ciclos em um grafo dirigido dado por listas de adjacência.
///
/// Retorna um ciclo representativo por componente fortemente conexo, como
/// caminho fechado (`[a, b, a]`). Laços (`a -> a`) também são ciclos.
List<List<String>> findCycles(Map<String, Set<String>> edges) {
  final nodes = {...edges.keys, for (final targets in edges.values) ...targets}
      .toList()
    ..sort();
  var counter = 0;
  final index = <String, int>{};
  final low = <String, int>{};
  final stack = <String>[];
  final onStack = <String>{};
  final cycles = <List<String>>[];

  void connect(String node) {
    index[node] = low[node] = counter++;
    stack.add(node);
    onStack.add(node);
    for (final next in (edges[node] ?? const <String>{}).toList()..sort()) {
      if (!index.containsKey(next)) {
        connect(next);
        low[node] = low[node]! < low[next]! ? low[node]! : low[next]!;
      } else if (onStack.contains(next)) {
        low[node] = low[node]! < index[next]! ? low[node]! : index[next]!;
      }
    }
    if (low[node] == index[node]) {
      final component = <String>[];
      String member;
      do {
        member = stack.removeLast();
        onStack.remove(member);
        component.add(member);
      } while (member != node);
      final selfLoop = edges[node]?.contains(node) ?? false;
      if (component.length > 1 || selfLoop) {
        cycles.add(_closedPath(component.toSet(), edges));
      }
    }
  }

  for (final node in nodes) {
    if (!index.containsKey(node)) connect(node);
  }
  return cycles;
}

/// Menor caminho fechado dentro de um componente fortemente conexo, começando
/// pelo menor nó em ordem alfabética (busca em largura).
List<String> _closedPath(Set<String> component, Map<String, Set<String>> edges) {
  final start = (component.toList()..sort()).first;
  List<String> successors(String node) =>
      (edges[node] ?? const <String>{}).where(component.contains).toList()
        ..sort();

  final parent = <String, String>{};
  final queue = <String>[start];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    for (final next in successors(current)) {
      if (next == start) {
        final path = [current];
        while (path.last != start) {
          path.add(parent[path.last]!);
        }
        return [...path.reversed, start];
      }
      if (!parent.containsKey(next)) {
        parent[next] = current;
        queue.add(next);
      }
    }
  }
  // Inalcançável para um componente fortemente conexo com ciclo.
  return [start, start];
}

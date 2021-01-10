import 'package:test/test.dart';

import 'package:frock_runtime/lifetime.dart';

void main() {
  test('test handler removed', () {
    var handled = false;
    final handler = () => handled = true;
    
    final lifetime = PlainLifetime();
    lifetime.add(handler);
    lifetime.remove(handler);
    lifetime.terminate();

    expect(handled, equals(false));
  });

  test('test function ref handler removed', () {
    final handler = _Handler();

    final lifetime = PlainLifetime();
    lifetime.add(handler.handle);
    lifetime.remove(handler.handle);
    lifetime.terminate();

    expect(handler.terminated, equals(false));
  });
}

class _Handler {
  var terminated = false;

  void handle() {
    terminated = true;
  }
}

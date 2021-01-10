import 'lifetime.dart';
import 'property.dart';

typedef ValueViewCode<T> = void Function(Lifetime valueLifetime, T value);

extension SourceLifetimeExt<T> on Source<T> {
  void view(Lifetime lifetime, ValueViewCode<T> viewer) {
    final lifetimes = PlainLifetimesSequence(lifetime);
    observe(lifetime, (value) {
      final valueLifetime = lifetimes.next();
      viewer(valueLifetime, value);
    });
  }
}

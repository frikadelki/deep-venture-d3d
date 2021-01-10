import 'lifetime.dart';
import 'property.dart';

extension SourceRx<T> on Source<T> {
  Source<K> map<K>(MapCode<T, K> mapper) => MapSource(this, mapper);

  Source<T> skip(int count) => SkipSource(this, count);
}

extension BoolSourceRx on Source<bool> {
  Source<bool> negate() => map((value) => !value);
}

extension SourcesIterableRx<T> on Iterable<Source<T>> {
  Source<T> merge() => MergeSource(this);
}

extension PropertyRx<T> on Property<T> {
  Property<K> map<K>(MapCode<T, K> mapper) => MapProperty(this, mapper);
}

extension BoolPropertyRx on Property<bool> {
  Property<bool> negate() => map((value) => !value);
}

extension ValueSources<T> on T {
  ConstProperty<T> constProp() => ConstProperty(this);
}

typedef MapCode<TIn, TOut> = TOut Function(TIn);

class MapSource<TIn, TOut> implements Source<TOut> {
  final Source<TIn> source;

  final MapCode<TIn, TOut> map;

  MapSource(this.source, this.map);

  @override
  void observe(Lifetime lifetime, Sink<TOut> sink) {
    source.observe(lifetime, (inValue) {
      sink(map(inValue));
    });
  }
}

class MapProperty<TIn, TOut> implements Property<TOut> {
  final Property<TIn> source;

  final MapCode<TIn, TOut> map;

  MapProperty(this.source, this.map);

  @override
  TOut get value => map(source.value);

  @override
  void observe(Lifetime lifetime, Sink<TOut> sink) {
    source.observe(lifetime, (inValue) {
      sink(map(inValue));
    });
  }
}

class SkipSource<T> implements Source<T> {
  final Source<T> source;

  final int count;

  SkipSource(this.source, this.count);

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    var skip = count;
    source.observe(lifetime, (it) {
      if (skip <= 0) {
        sink(it);
      } else {
        skip--;
      }
    });
  }
}

class MergeSource<T> implements Source<T> {
  final Iterable<Source<T>> sources;

  MergeSource(this.sources);

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    for (final source in sources) {
      source.observe(lifetime, sink);
    }
  }
}

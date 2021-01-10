
import 'lifetime.dart';
import 'property_rx.dart';
import 'utils.dart';

typedef Sink<T> = void Function(T value);

abstract class Source<T> {
  void observe(Lifetime lifetime, Sink<T> sink);
}

class EmptySource<T> implements Source<T> {
  const EmptySource();

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
  }
}

class Signal<T> implements Source<T> {
  final _observers = <Sink<T>>[];

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    _observers.add(sink);
    lifetime.add(() => _observers.remove(sink));
  }

  void signal(T value) {
    _observers.forEach((sink) => sink(value));
  }
}

abstract class Property<T> implements Source<T> {
  T get value;
}

class ConstProperty<T> implements Property<T> {
  @override
  final T value;

  const ConstProperty(this.value);

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    sink(value);
  }
}

abstract class MutableProperty<T> implements Property<T> {
  set value(T value);
}

class ValueProperty<T> implements MutableProperty<T> {
  final _signal = Signal<T>();

  T _value;

  ValueProperty(this._value);

  @override
  T get value => _value;

  @override
  set value(T value) {
    _value = value;
    _signal.signal(value);
  }

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    _signal.observe(lifetime, sink);
    sink(_value);
  }
}

abstract class ListProperty<T> extends Property<Iterable<T>> {
  int get length;
}

extension ListPropertyOps<T> on ListProperty<T> {
  Property<int> get lengthProperty => map((_) => length);

  bool get isEmpty => length <= 0;
}

abstract class MutableListProperty<T> extends ListProperty<T> {
  void add(T item);

  void removeAt(int index);
}

extension MutableListPropertyOps<T> on MutableListProperty<T> {
  void removeLast() {
    assert(!isEmpty);
    removeAt(length - 1);
  }
}

class ValueListProperty<T> implements MutableListProperty<T> {
  final _signal = Signal<Iterable<T>>();

  final _value = <T>[];

  @override
  Iterable<T> get value => _value;

  @override
  int get length => _value.length;

  void _notify() {
    _signal.signal(value);
  }

  NumRange<int> get _range => NumRange(0, length - 1);

  @override
  void add(T item) {
    _value.add(item);
    _notify();
  }

  @override
  void removeAt(int index) {
    assert(_range.isInRange(index));
    if (!_range.isInRange(index)) {
      return;
    }
    _value.removeAt(index);
    _notify();
  }

  @override
  void observe(Lifetime lifetime, Sink<Iterable<T>> sink) {
    _signal.observe(lifetime, sink);
    sink(value);
  }
}

class ComputedProperty<T> implements Property<T> {
  final _signal = Signal<T>();

  final T Function() _compute;

  ComputedProperty(this._compute);

  void signal() {
    _signal.signal(value);
  }

  @override
  T get value => _compute();

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    _signal.observe(lifetime, sink);
    sink(value);
  }
}

typedef DelegateSourceObserve<T> =
  void Function(Lifetime lifetime, Sink<T> sink);

class DelegateSource<T> implements Source<T> {
  final DelegateSourceObserve<T> _code;

  DelegateSource(this._code);

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    _code(lifetime, sink);
  }
}

typedef DelegatePropertyGet<T> = T Function();

class DelegateProperty<T> implements Property<T> {
  final DelegatePropertyGet<T> _getter;

  final DelegateSourceObserve<T> _observe;

  DelegateProperty(this._getter, this._observe);

  factory DelegateProperty.withSignal(
    DelegatePropertyGet<T> getter,
    Source<void> signal
  ) {
    return DelegateProperty<T>(getter, (lifetime, sink) {
      signal.observe(lifetime, (_) => sink(getter()));
    });
  }

  @override
  T get value => _getter();

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    _observe(lifetime, sink);
  }
}

class ProxyProperty<T> implements MutableProperty<T> {
  final _signal = Signal<void>();
  
  final T Function() _getter;

  final void Function(T value) _setter;

  ProxyProperty(this._getter, this._setter);

  @override
  T get value => _getter();
  
  @override
  set value(T value) {
    _setter(value);
    _signal.signal(null);
  }

  @override
  void observe(Lifetime lifetime, Sink<T> sink) {
    _signal.observe(lifetime, (_) { 
      sink(value);
    });
    sink(value);
  }
   // external change
  void signal() {
    _signal.signal(null);
  }
} 

class LifetimeAliveProperty implements Property<bool> {
  final Lifetime targetLifetime;

  LifetimeAliveProperty(this.targetLifetime);

  @override
  bool get value => !targetLifetime.isTerminated;

  @override
  void observe(Lifetime sinkLifetime, Sink<bool> sink) {
      final _sink0 = () {
        sink(value);
      };
      targetLifetime.add(_sink0);
      sinkLifetime.add(() {
        targetLifetime.remove(_sink0);
      });
      _sink0();
  }
}

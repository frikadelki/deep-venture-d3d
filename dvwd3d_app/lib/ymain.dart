import 'dart:math' as math;
import 'dart:web_gl' as gl;

import 'package:frock_runtime/frock_runtime.dart';
import 'package:vector_math/vector_math.dart';

import 'engine/lights.dart';
import 'engine/program.dart';
import 'misc/mesh.dart';
import 'misc/scene.dart';
import 'misc/utils.dart';
import 'ymain/grid.dart';
import 'ymain/grid_geometry.dart';
import 'ymain/pawn.dart';

class YMain_SceneDelegate implements SceneDelegate {
  final _lifetime = PlainLifetime();

  final gl.RenderingContext _glContext;

  YMainScene? _scene;

  YMain_SceneDelegate(this._glContext) {
    _scene = YMainScene(_lifetime, _glContext);
  }

  @override
  void onKeyDown(SceneKeyCode code) {
    _checkDisposed();
    _scene!.handleAction(code);
  }

  @override
  void animate(num timestamp) {
    _checkDisposed();
    _scene!.animate(timestamp);
  }

  @override
  void render() {
    _checkDisposed();
    _scene!.draw();
  }

  @override
  void resize(int width, int height) {
    _checkDisposed();
    _scene!.resize(width, height);
  }

  @override
  void dispose() {
    _checkDisposed();
    _lifetime.terminate();
    _scene = null;
  }

  void _checkDisposed() {
    if (_lifetime.isTerminated) {
      throw StateError('This scene was disposed of.');
    }
  }
}

class _C {
  static final ClearColor = Vector4(0.02, 0.02, 0.02, 1.0);

  static final AmbientColor = Vector3(0.02, 0.02, 0.02);

  static final SceneLightsCount = 3;

  static final SceneLightPoleColor = Vector3(0.2, 0.2, 0.7);

  static final SceneLightPoleFade = 0.2;

  static final SceneLightPole1 = GridVector(3, -6, 2);

  static final SceneLightPole2 = GridVector(9, -6, 2);

  static final AvatarMoveTime = 640.0;

  static final AvatarStartCoordinate = GridVector(6, 3, 0);

  static final AvatarStartDirection = GridAbsoluteDirection.North;

  static final AvatarHeight = 1.5;
  
  static final AvatarLanternColor = Vector3(0.5, 0.4, 0.2);

  static final AvatarLanternFade = 0.3;

  static final CubeDiffuseColor = Vector3(0.2, 0.7, 0.3);

  static final CubeSpecularColor = Vector4(0.2, 0.7, 0.2, 16.0);

  static final CoinDiffuseColor = Vector3(0.7, 0.3, 0.5);

  static final CoinSpecularColor = Vector4(0.9, 0.4, 0.4, 32.0);

  static final GridCellSize = 1.0;

  static final ZNear = 0.001;

  static final ZFar = 25.0;

  static final FovYDegrees = 75.0;

  static final FovYRadians = math.pi * FovYDegrees / 180.0;
}

final _GridFloor = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
];

final _GridWalls1 = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1 ],
  <int>[ 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1 ],
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1 ],
  <int>[ 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
];

final _GridWalls2 = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
];

final _Ceiling1 = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
  <int>[ 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1 ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
];

final _Ceiling2 = [
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
  <int>[ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ],
];

class YMainScene {
  final Lifetime _lifetime;

  final gl.RenderingContext _glContext;

  late final Assets _assets;

  late final GridProgram _gridProgram;

  late final PawnProgram _pawnProgram;

  late final Grid _grid;
  
  final _pawns = <GridPawn>[];

  late final Avatar _avatar;

  final _lights = LightsData();

  final _camera = Camera();

  factory YMainScene(Lifetime lifetime, gl.RenderingContext glContext) {
    try {
      return YMainScene._(lifetime, glContext);
    } on ProgramException catch (e) {
      print('Exception while loading ymain scene:\n${e.reason}\n${e.infoLog}');
      rethrow;
    }
  }

  YMainScene._(this._lifetime, this._glContext) {
    _assets = Assets(_glContext);
    _gridProgram = GridProgram(_glContext, _C.SceneLightsCount);
    _pawnProgram = PawnProgram(_glContext, _C.SceneLightsCount);

    final gridGeometry = GridGeometry(_C.GridCellSize);

    _grid = Grid(
      gridGeometry,
      _assets.cubeMeshData,
      _C.CubeDiffuseColor,
      _C.CubeSpecularColor);
    _grid.importLayer(_GridFloor, -1);
    _grid.importLayer(_GridWalls1, 0);
    _grid.importLayer(_GridWalls2, 1);
    _grid.importLayer(_Ceiling1, 2);
    _grid.importLayer(_Ceiling2, 3);

    void addCoin(GridVector coordinate) {
      final coin = GridPawn(
        gridGeometry,
        _assets.coinMeshData,
        _C.CoinDiffuseColor,
        _C.CoinSpecularColor);
      coin
        ..moveTo(coordinate);
      _pawns.add(coin);
    }
    addCoin(GridVector(4, -7, 1));
    addCoin(GridVector(8, -7, 1));


    _avatar = Avatar(gridGeometry);

    _lights.ambientColor.setFrom(_C.AmbientColor);
    _lights.pointLights.add(_avatar.lantern);

    void addLightPole(GridVector coordinate) {
      final light = PointLight();
      light.color.setFrom(_C.SceneLightPoleColor);
      light.fadeK = _C.SceneLightPoleFade;
      gridGeometry.calcTranslationVector(light.origin, coordinate);
      _lights.pointLights.add(light);
    }
    addLightPole(_C.SceneLightPole1);
    addLightPole(_C.SceneLightPole2);

    _trackAvatar();
    
    _lifetime.add(_dispose);
  }

  void _dispose() {
    _gridProgram.dispose();
    _pawnProgram.dispose();
    _assets.dispose();
  }

  void _trackAvatar() {
    void update(void _) {
      _camera.setLookAt(_avatar.eye, _avatar.lookAt, _avatar.up);
    }
    
    _avatar.onWorldUpdate.observe(_lifetime, update);
    update(null);
  }

  void handleAction(SceneKeyCode code) {
    switch (code) {
      case SceneKeyCode.W:
        _avatar.strafe(GridRelativeDirection.Forward);
        break;

      case SceneKeyCode.A:
        _avatar.strafe(GridRelativeDirection.Left);
        break;

      case SceneKeyCode.S:
        _avatar.strafe(GridRelativeDirection.Backward);
        break;

      case SceneKeyCode.D:
        _avatar.strafe(GridRelativeDirection.Right);
        break;

      case SceneKeyCode.Q:
        _avatar.rotate(GridRotation.Left);
        break;

      case SceneKeyCode.E:
        _avatar.rotate(GridRotation.Right);
        break;

      case SceneKeyCode.R:
        _avatar.reset();
        break;
    }
  }

  void animate(num timestamp) {
    _avatar.animate(timestamp);
    for (final pawn in _pawns) {
      final angle = 16 * (timestamp / 1000) * (math.pi / 180);
      pawn.transform.setRotation(x: angle, y: angle, z: angle);
    }
  }

  void draw() {
    _glContext.enable(gl.WebGL.CULL_FACE);
    _glContext.cullFace(gl.WebGL.BACK);
    _glContext.frontFace(gl.WebGL.CCW);
    _glContext.enable(gl.WebGL.DEPTH_TEST);
    _glContext.clearColorFrom(_C.ClearColor);
    _glContext.clear(gl.WebGL.COLOR_BUFFER_BIT | gl.WebGL.DEPTH_BUFFER_BIT);

    _drawGrid();
    _drawPawns();
  }

  void _drawGrid() {
    _gridProgram.setup(_lights, _camera);
    _gridProgram.draw(_grid);
  }

  void _drawPawns() {
    _pawnProgram.setup(_lights, _camera);
    for (final pawn in _pawns) {
      _pawnProgram.draw(pawn);
    }
  }

  void resize(int width, int height) {
    final aspectRatio = width / height;
    _camera.setPerspective(_C.FovYRadians, aspectRatio, _C.ZNear, _C.ZFar);
    _glContext.viewport(0, 0, width, height);
  }
}

class Assets {
  final gl.RenderingContext _glContext;

  final _buffers = <DisposableBuffers>[];
  
  late final CubeMeshData cubeMeshData;

  late final CylinderMeshData coinMeshData;
  
  Assets(this._glContext) {
    cubeMeshData = CubeMeshData.cube(_glContext, 1.0);
    _buffers.add(cubeMeshData);
    coinMeshData = CylinderMeshData.coin(_glContext, 0.3, 0.1);
    _buffers.add(coinMeshData);
  }
  
  void dispose() {
    for (final disposable in _buffers) {
      disposable.disposeBuffers(_glContext);
    }
    _buffers.clear();
  }
}

class Avatar {
  final GridGeometry _gridGeometry;

  final _coordinate = ValueProperty(GridVector.zero());

  final _direction = ValueProperty(GridAbsoluteDirection.North);

  final _onWorldUpdate = Signal<void>();

  Source<void> get onWorldUpdate => _onWorldUpdate;

  final eye = Vector3.zero();
  
  final _worldDirection = Vector3.zero();

  final up = Vector3(0.0, 1.0, 0.0);

  final lookAt = Vector3.zero();

  final lantern = PointLight();

  Activity? _currentMove;

  Avatar(this._gridGeometry) {
    lantern.color.setFrom(_C.AvatarLanternColor);
    lantern.fadeK = _C.AvatarLanternFade;
    reset();
  }

  bool get _canMove {
    return _currentMove == null;
  }

  void _startMove(Activity move) {
    if (!_canMove) {
      assert(false);
      return;
    }
    _currentMove = move;
  }

  void animate(num timestamp) {
    final move = _currentMove;
    if (move == null) {
      return;
    }
    move.animate(timestamp);
    if (move.finished) {
      _currentMove = null;
      _snapWorld();
    }
  }

  void reset() {
    if (!_canMove) {
      return;
    }
    final newCoordinate = _C.AvatarStartCoordinate;
    final newDirection = _C.AvatarStartDirection;
    _coordinate.value = newCoordinate;
    _direction.value = newDirection;
    _snapWorld();
  }

  void strafe(GridRelativeDirection relativeDirection) {
    if (!_canMove) {
      return;
    }
    final oldCoordinate = _coordinate.value;
    final absoluteDirection = _direction.value.relative(relativeDirection);
    final newCoordinate = oldCoordinate.add(absoluteDirection.gridVector);

    _coordinate.value = newCoordinate;

    _startStrafe(oldCoordinate, newCoordinate);
  }

  void _startStrafe(GridVector from, GridVector to) {
    final _eyeOld = Vector3.zero();
    final _eyeNew = Vector3.zero();
    _calcEye(_eyeOld, from);
    _calcEye(_eyeNew, to);
    void _step(double t) {
      eye
        ..setFrom(_eyeNew)
        ..sub(_eyeOld)
        ..scale(t)
        ..add(_eyeOld);
      _updateWorld();
    }
    _startMove(DelegateActivity(_C.AvatarMoveTime, _step));
  }

  void rotate(GridRotation rotation) {
    if (!_canMove) {
      return;
    }
    final oldDirection = _direction.value;
    final newDirection = oldDirection.rotate(rotation);

    _direction.value = newDirection;

    _startRotate(oldDirection, newDirection);
  }

  void _startRotate(GridAbsoluteDirection from, GridAbsoluteDirection to) {
    final fromV = from.worldVector;
    final toV = to.worldVector;
    final cross = toV.cross(fromV)..normalize();
    final fullAngle = math.acos(fromV.dot(toV));
    void _step(double t) {
      final dAngle = fullAngle * t;
      final q = Quaternion.axisAngle(cross, dAngle);
      _worldDirection.setFrom(fromV);
      q.rotate(_worldDirection);
      _worldDirection.normalize();
      _updateWorld();
    }
    _startMove(DelegateActivity(_C.AvatarMoveTime, _step));
  }

  void _calcEye(Vector3 eyeOut, GridVector coordinate) {
    _gridGeometry.calcTranslationVector(eyeOut, coordinate);
    eyeOut.y += _C.AvatarHeight - _gridGeometry.cellSize / 2.0;
  }

  void _snapWorld() {
    _calcEye(eye, _coordinate.value);
    _worldDirection
      ..setFrom(_direction.value.worldVector)
      ..normalize();
    _updateWorld();
  }

  void _updateWorld() {
    lookAt.setFrom(eye);
    lookAt.add(_worldDirection);

    final tmp = Vector3.zero()
      ..setFrom(up)
      ..normalize()
      ..scale(-0.1);
    lantern.origin
      ..setFrom(_worldDirection)
      ..normalize()
      ..scale(0.1)
      ..add(eye)
      ..add(tmp)
      ;
    //lantern.origin.setFrom(eye);
    _onWorldUpdate.signal(null);
  }
}

abstract class Activity {
  bool get finished;

  void animate(num timestamp);
}

class DelegateActivity implements Activity {
  final double _lengthMillis;

  final void Function(double t) _update;

  num? _startedTimestamp;

  bool _finished = false;

  @override
  bool get finished => _finished;

  DelegateActivity(this._lengthMillis, this._update);

  @override
  void animate(num timestamp) {
    if (_finished) {
      assert(false);
      return;
    }
    final startedTimestamp = _startedTimestamp;
    if (startedTimestamp == null) {
      _startedTimestamp = timestamp;
      return;
    }
    final elapsed = math.min(timestamp - startedTimestamp, _lengthMillis);
    final t = elapsed / _lengthMillis;
    _update(t);
    if (elapsed >= _lengthMillis) {
      _finished = true;
    }
  }
}

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

class TestScene_03_Delegate implements SceneDelegate {
  final gl.RenderingContext _glContext;

  late final TestScene03 _scene;

  TestScene_03_Delegate(this._glContext) {
    _scene = TestScene03(_glContext);
  }

  @override
  void onKeyDown(SceneKeyCode code) {
    _scene.handleAction(code);
  }

  @override
  void animate(num timestamp) {
    _scene.animate(timestamp);
  }

  @override
  void render() {
    _scene.draw();
  }

  @override
  void resize(int width, int height) {
    _glContext.viewport(0, 0, width, height);
    _scene.resize(width, height);
  }

  @override
  void dispose() {
    _scene.dispose();
  }
}

class _C {
  static final ClearColor = Vector4(0.1, 0.1, 0.1, 1.0);

  static final AmbientColor = Vector3(0.16, 0.16, 0.16);

  static final AvatarStartCoordinate = GridVector(3, 3, 0);

  static final AvatarStartDirection = GridAbsoluteDirection.North;

  static final AvatarHeight = 1.5;
  
  static final AvatarLanternColor = Vector3(0.5, 0.4, 0.1);

  static final CubeDiffuseColor = Vector3(0.2, 0.7, 0.3);

  static final CubeSpecularColor = Vector4(0.2, 0.7, 0.2, 0.25);

  static final CoinDiffuseColor = Vector3(0.7, 0.3, 0.5);

  static final CoinSpecularColor = Vector4(0.7, 0.2, 0.2, 0.25);

  static final GridCellSize = 1.0;

  static final ZNear = 0.001;

  static final ZFar = 10.0;

  static final FovYDegrees = 75.0;

  static final FovYRadians = math.pi * FovYDegrees / 180.0;
}

class TestScene03 {
  final _lifetime = PlainLifetime();

  final gl.RenderingContext _glContext;

  late final Assets _assets;

  late final GridProgram _gridProgram;

  late final PawnProgram _pawnProgram;

  late final Grid _grid;
  
  final _pawns = <GridPawn>[];

  late final Avatar _avatar;

  final _lights = LightsData();

  final _camera = Camera();

  factory TestScene03(gl.RenderingContext glContext) {
    try {
      return TestScene03._(glContext);
    } on ProgramException catch (e) {
      print('Exception while loading test scene 3:\n${e.reason}\n${e.infoLog}');
      rethrow;
    }
  }

  TestScene03._(this._glContext) {
    _assets = Assets(_glContext);
    _gridProgram = GridProgram(_glContext);
    _pawnProgram = PawnProgram(_glContext);

    final gridGeometry = GridGeometry(_C.GridCellSize);

    _grid = Grid(
      gridGeometry,
      _assets.cubeMeshData,
      _C.CubeDiffuseColor,
      _C.CubeSpecularColor);
    _grid.importLayer(_GridFloor, -1);
    _grid.importLayer(_GridWalls1, 0);
    _grid.importLayer(_GridWalls2, 1);
    _grid.importLayer(_Ceiling2, 2);
    
    final coin1 = GridPawn(
      gridGeometry,
      _assets.coinMeshData,
      _C.CoinDiffuseColor,
      _C.CoinSpecularColor);
    coin1
      ..moveTo(GridVector(3, -4, 1));
    _pawns.add(coin1);

    _avatar = Avatar(gridGeometry);

    _lights.ambientColor.setFrom(_C.AmbientColor);
    _lights.pointLights.add(_avatar.lantern);

    _avatar.onWorldUpdate.observe(_lifetime, (_) {
      _updateFromAvatar();
    });
    _updateFromAvatar();
  }

  void _updateFromAvatar() {
    _camera.setLookAt(_avatar.eye, _avatar.lookAt, _avatar.up);
  }

  void handleAction(SceneKeyCode code) {
    switch (code) {
      case SceneKeyCode.W:
        _avatar.move(GridRelativeDirection.Forward);
        break;

      case SceneKeyCode.A:
        _avatar.move(GridRelativeDirection.Left);
        break;

      case SceneKeyCode.S:
        _avatar.move(GridRelativeDirection.Backward);
        break;

      case SceneKeyCode.D:
        _avatar.move(GridRelativeDirection.Right);
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
    for (final pawn in _pawns) {
      final angle = 10 * (timestamp / 1000) * (math.pi / 180);
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

    drawGrid();
    drawPawns();
  }

  void drawGrid() {
    _gridProgram.setup(_lights, _camera);
    _gridProgram.draw(_grid);
  }

  void drawPawns() {
    _pawnProgram.setup(_lights, _camera);
    for (final pawn in _pawns) {
      _pawnProgram.draw(pawn);
    }
  }

  void resize(int width, int height) {
    final aspectRatio = width / height;
    _camera.setPerspective(_C.FovYRadians, aspectRatio, _C.ZNear, _C.ZFar);
  }

  void dispose() {
    _gridProgram.dispose();
    _pawnProgram.dispose();
    _assets.dispose();
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

  Source<void> get onWorldUpdate => [ _coordinate, _direction ].merge();

  final eye = Vector3.zero();

  final up = Vector3(0.0, 1.0, 0.0);

  final lookAt = Vector3.zero();

  final lantern = PointLight();

  Avatar(this._gridGeometry) {
    _direction.value;
    lantern.color.setFrom(_C.AvatarLanternColor);
    reset();
  }

  void reset() {
    final newCoordinate = _C.AvatarStartCoordinate;
    final newDirection = _C.AvatarStartDirection;
    _updateWorld(newCoordinate, newDirection);
    _coordinate.value = newCoordinate;
    _direction.value = newDirection;
  }

  void move(GridRelativeDirection relativeDirection) {
    final oldCoordinate = _coordinate.value;
    final absoluteDirection = _direction.value.relative(relativeDirection);
    final newCoordinate = oldCoordinate.add(absoluteDirection.gridVector);
    _updateWorld(newCoordinate, _direction.value);
    _coordinate.value = newCoordinate;
  }

  void rotate(GridRotation rotation) {
    final newDirection = _direction.value.rotate(rotation);
    _updateWorld(_coordinate.value, newDirection);
    _direction.value = newDirection;
  }

  void _updateWorld(GridVector coordinate, GridAbsoluteDirection direction) {
    _gridGeometry.calcTranslationVector(
      eye, coordinate, _gridGeometry.cellSize);
    eye.y += _C.AvatarHeight - _gridGeometry.cellSize / 2.0;

    lookAt.setFrom(eye);
    lookAt.add(direction.worldVector);

    final tmp = Vector3.zero()
      ..setFrom(up)
      ..normalize()
      ..scale(-0.3);
    lantern.origin
      ..setFrom(direction.worldVector)
      ..normalize()
      ..scale(0.2)
      ..add(eye)
      ..add(tmp);
  }
}

final _GridFloor = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 0, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 0, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
];

final _GridWalls1 = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 1, ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 1, ],
  <int>[ 0, 0, 0, 0, 0, 0, 0, 1, ],
  <int>[ 1, 1, 1, 0, 0, 0, 0, 1, ],
  <int>[ 1, 1, 0, 0, 0, 1, 0, 1, ],
  <int>[ 1, 1, 0, 0, 0, 0, 0, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
];

final _GridWalls2 = [
  <int>[ 0, 0, 0, 1, 1, 1, 0, 0, ],
  <int>[ 0, 1, 0, 0, 1, 1, 0, 0, ],
  <int>[ 1, 0, 0, 0, 0, 0, 0, 0, ],
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, ],
  <int>[ 1, 1, 0, 0, 0, 1, 0, 0, ],
  <int>[ 0, 1, 0, 0, 0, 1, 0, 0, ],
  <int>[ 0, 1, 0, 0, 0, 0, 0, 0, ],
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, ],
];

final _Ceiling = [
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, ],
  <int>[ 0, 1, 1, 1, 0, 1, 0, 0, ],
  <int>[ 1, 0, 1, 1, 0, 0, 0, 0, ],
  <int>[ 0, 0, 1, 1, 0, 0, 0, 0, ],
  <int>[ 1, 1, 1, 1, 0, 1, 0, 0, ],
  <int>[ 0, 1, 0, 0, 0, 1, 0, 0, ],
  <int>[ 0, 1, 0, 0, 0, 0, 0, 0, ],
  <int>[ 0, 0, 0, 0, 0, 0, 0, 0, ],
];

final _Ceiling2 = [
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
  <int>[ 1, 1, 1, 1, 1, 1, 1, 1, ],
];


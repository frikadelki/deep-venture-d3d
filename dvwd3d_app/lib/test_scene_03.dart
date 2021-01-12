import 'dart:math' as math;
import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';
import 'package:frock_runtime/frock_runtime.dart';

import 'render_lights.dart';
import 'render_primitives.dart';
import 'render_program.dart';
import 'render_root.dart';
import 'render_scene.dart';

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

ProgramSource TestProgram03_Source(LightsSnippet lights) => ProgramSource(
'TestProgram_03',

'''
precision mediump float;

uniform mat4 viewProjectionMatrix;

uniform mat4 modelMatrix;

uniform mat4 normalsMatrix;

attribute vec3 position;

attribute vec3 normal;

attribute vec2 texCoord;

varying vec3 varPosition;

varying vec3 varNormal;

varying vec2 varTexCoord;

void main() {
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  varPosition = vec3(worldPosition) / worldPosition.w;
  varNormal = normalize(normalsMatrix * vec4(normal, 0.0)).xyz;
  varTexCoord = texCoord;
  gl_Position = viewProjectionMatrix * worldPosition;
}
''',

'''
precision mediump float;

${lights.source}

uniform vec3 cameraEyePosition;

uniform vec3 modelColorDiffuse;

uniform vec4 modelColorSpecular;

varying vec3 varPosition;

varying vec3 varNormal;

varying vec2 varTexCoord;

const float TCD_THRESHOLD = 0.02;

void main() {
  LightsIntensity light = lightsIntensity(
    varPosition, varNormal, cameraEyePosition, modelColorSpecular.w);
  vec3 diffuseColor = (light.ambient + light.diffuse) * modelColorDiffuse;
  vec3 specularColor = light.specular * modelColorSpecular.xyz;
  float tcdx = 0.5 - abs(varTexCoord.x - 0.5);
  float tcdy = 0.5 - abs(varTexCoord.y - 0.5);
  float tcdMin = min(tcdx, tcdy);
  float attune = 1.0;
  if (tcdMin <= TCD_THRESHOLD) {
    attune = 0.4 + 0.6 * tcdMin / TCD_THRESHOLD;
  }
  vec3 color = attune * (diffuseColor + specularColor);
  gl_FragColor = vec4(color, 1.0);
}
'''
);

class TestProgram_03  {
  final gl.RenderingContext _glContext;

  late final Program _program;

  late final Uniform _viewProjectionMatrix;

  late final Uniform _modelMatrix;

  late final Uniform _normalsMatrix;

  late final VertexAttribute _position;

  late final VertexAttribute _normal;

  late final VertexAttribute _texCoord;

  late final LightsBinding _lightsBinding;

  late final Uniform _cameraEyePosition;

  late final Uniform _modelColorDiffuse;

  late final Uniform _modelColorSpecular;

  late final IndicesArray _indicesArray;

  TestProgram_03._(this._glContext) {
    final lightsSnippet = LightsSnippet(2);
    final source = TestProgram03_Source(lightsSnippet);
    _program = Program(_glContext, source);
    _viewProjectionMatrix = _program.getUniform('viewProjectionMatrix');
    _modelMatrix = _program.getUniform('modelMatrix');
    _normalsMatrix = _program.getUniform('normalsMatrix');
    _position = _program.getVertexAttribute('position');
    _normal = _program.getVertexAttribute('normal');
    _texCoord = _program.getVertexAttribute('texCoord');
    _lightsBinding = lightsSnippet.makeBinding(_program);
    _cameraEyePosition = _program.getUniform('cameraEyePosition');
    _modelColorDiffuse = _program.getUniform('modelColorDiffuse');
    _modelColorSpecular = _program.getUniform('modelColorSpecular');
    _indicesArray = IndicesArray(_glContext);
    _program.drawCalls = CustomDrawCalls((glContext) {
      _indicesArray.drawAllTriangles();
    });
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

  late final TestProgram_03 _program;

  late final Grid _grid;
  
  final _floaters = <GridPawn>[];

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
    _program = TestProgram_03._(_glContext);

    final gridGeometry = GridGeometry(_C.GridCellSize);

    _grid = Grid(gridGeometry);
    _grid.importLayer(_GridFloor, -1);
    _grid.importLayer(_GridWalls1, 0);
    _grid.importLayer(_GridWalls2, 1);
    _grid.importLayer(_Ceiling2, 2);
    
    final coin1 = GridPawn(gridGeometry, _assets.coinMeshData)
      ..moveTo(GridVector(3, -4, 1));
    _floaters.add(coin1);

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
    for (final pawn in _floaters) {
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

    _program._viewProjectionMatrix.data = Matrix4UniformData(
      _camera.viewProjectionMatrix);
    _program._lightsBinding.data = _lights;
    _program._cameraEyePosition.data = Vector3UniformData(_camera.eyePosition);
    for (final matrix in _grid._voxelsMatrices) {
      _drawGridVoxel(matrix);
    }
    for (final object in _floaters) {
      _drawObject(object);
    }
  }

  void _drawObject(GridPawn object) {
    _program._modelMatrix.data = object.modelMatrixData;
    _program._normalsMatrix.data = object.normalsMatrixData;
    _program._position.data = object.meshData.positionsData;
    _program._normal.data = object.meshData.normalsData;
    _program._texCoord.data = object.meshData.texCoordData;
    _program._modelColorDiffuse.data = Vector3UniformData(_C.CoinDiffuseColor);
    _program._modelColorSpecular.data = Vector4UniformData(_C.CoinSpecularColor);
    _program._indicesArray.data = object.meshData.indices;
    _program._program.draw();
  }

  void _drawGridVoxel(Matrix4 modelMatrix) {
    _program._modelMatrix.data = Matrix4UniformData(modelMatrix);
    _program._normalsMatrix.data = Matrix4UniformData(Matrix4.identity());
    final meshData = _assets.cubeMeshData;
    _program._position.data = meshData.positionsData;
    _program._normal.data = meshData.normalsData;
    _program._texCoord.data = meshData.texCoordData;
    _program._modelColorDiffuse.data = Vector3UniformData(_C.CubeDiffuseColor);
    _program._modelColorSpecular.data = Vector4UniformData(_C.CubeSpecularColor);
    _program._indicesArray.data = meshData.indices;
    _program._program.draw();
  }

  void resize(int width, int height) {
    final aspectRatio = width / height;
    _camera.setPerspective(_C.FovYRadians, aspectRatio, _C.ZNear, _C.ZFar);
  }

  void dispose() {
    _program._program.dispose();
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

class GridPawn {
  final GridGeometry _gridGeometry;

  final transform = Transform();

  late final Matrix4UniformData modelMatrixData;

  late final Matrix4UniformData normalsMatrixData;

  final MeshData meshData;

  GridPawn(this._gridGeometry, this.meshData) {
    moveTo(GridVector.zero());
    modelMatrixData = Matrix4UniformData(transform.modelMatrix);
    normalsMatrixData = Matrix4UniformData(transform.normalsMatrix);
  }

  void moveTo(GridVector coordinate) {
    final tmp = Vector3.zero();
    _gridGeometry.calcTranslationVector(tmp, coordinate, 1.0);
    transform.setTranslation(tmp);
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



class Grid {
  final GridGeometry _geometry;

  final _voxelsMatrices = <Matrix4>[];

  Grid(this._geometry);

  void importLayer(List<List<int>> data, int y) {
    for (var row = 0; row < data.length; row++) {
      final rowData = data[row];
      for (var column = 0; column < rowData.length; column++) {
        final value = rowData[column];
        if (value <= 0) {
          continue;
        }
        final coordinate = GridVector(row, -column, y);
        final matrix = Matrix4.identity();
        _geometry.calcTranslationMatrix(matrix, coordinate, _geometry.cellSize);
        _voxelsMatrices.add(matrix);
      }
    }
  }
}

enum GridRotation {
  Right,
  Left,
}

enum GridAbsoluteDirection {
  North,
  East,
  South,
  West,
}

class GridAbsoluteDirectionMeta {
  final GridVector gridVector;
  
  final Vector3 worldVector;
  
  final GridAbsoluteDirection opposite;

  final GridAbsoluteDirection right;

  final GridAbsoluteDirection left;

  GridAbsoluteDirectionMeta(
    this.gridVector, this.worldVector, this.opposite, this.right, this.left);
}

extension on GridAbsoluteDirection {
  static final _NorthMeta = GridAbsoluteDirectionMeta(
    GridVector(0, -1, 0), 
    Vector3(0.0, 0.0, -1.0),
    GridAbsoluteDirection.South,
    GridAbsoluteDirection.East,
    GridAbsoluteDirection.West);

  static final _EastMeta = GridAbsoluteDirectionMeta(
    GridVector(1, 0, 0),
    Vector3(1.0, 0.0, 0.0),
    GridAbsoluteDirection.West,
    GridAbsoluteDirection.South,
    GridAbsoluteDirection.North);

  static final _SouthMeta = GridAbsoluteDirectionMeta(
    GridVector(0, 1, 0),
    Vector3(0.0, 0.0, 1.0),
    GridAbsoluteDirection.North,
    GridAbsoluteDirection.West,
    GridAbsoluteDirection.East);

  static final _WestMeta = GridAbsoluteDirectionMeta(
    GridVector(-1, 0, 0),
    Vector3(-1.0, 0.0, 0.0),
    GridAbsoluteDirection.East,
    GridAbsoluteDirection.North,
    GridAbsoluteDirection.South);

  GridAbsoluteDirectionMeta get meta {
    switch (this) {
      case GridAbsoluteDirection.North:
        return _NorthMeta;
        
      case GridAbsoluteDirection.East:
        return _EastMeta;
        
      case GridAbsoluteDirection.South:
        return _SouthMeta;
        
      case GridAbsoluteDirection.West:
        return _WestMeta;
    }
  }

  GridVector get gridVector {
    return meta.gridVector;
  }
  
  Vector3 get worldVector {
    return meta.worldVector;
  }

  GridAbsoluteDirection relative(GridRelativeDirection relation) {
    switch (relation) {
      case GridRelativeDirection.Forward:
        return this;
        
      case GridRelativeDirection.Right:
        return meta.right;
        
      case GridRelativeDirection.Backward:
        return meta.opposite;
        
      case GridRelativeDirection.Left:
        return meta.left;
    }
  }

  GridAbsoluteDirection rotate(GridRotation rotation) {
    switch (rotation) {
      case GridRotation.Right:
        return meta.right;

      case GridRotation.Left:
        return meta.left;
    }
  }
}

enum GridRelativeDirection {
  Forward,
  Right,
  Backward,
  Left,
}

class GridVector {
  final int x;

  final int z;

  final int y;

  const GridVector(this.x, this.z, this.y);

  factory GridVector.zero() {
    return const GridVector(0, 0, 0);
  }

  GridVector add(GridVector d) {
    return GridVector(x + d.x, z + d.z, y + d.y);
  }

  void realWorldPoint(Vector3 translation, double cellSize, double objectSize) {
    final dSize = objectSize / 2.0;
    translation.setValues(
      x * cellSize + dSize,
      y * cellSize + dSize,
      z * cellSize + dSize);
  }
}

class GridGeometry {
  final double cellSize;

  final _tmp = Vector3.zero();

  GridGeometry(this.cellSize);

  void calcTranslationMatrix(
    Matrix4 mat, GridVector coordinate, double objectSize) {
    coordinate.realWorldPoint(_tmp, cellSize, objectSize);
    mat.setTranslation(_tmp);
  }

  void calcTranslationVector(
    Vector3 vector, GridVector coordinate, double objectSize) {
    coordinate.realWorldPoint(vector, cellSize, objectSize);
  }
}

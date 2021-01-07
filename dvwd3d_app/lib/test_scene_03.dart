import 'dart:math' as math;
import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';

import 'render_lights.dart';
import 'render_primitives.dart';
import 'render_program.dart';
import 'render_root.dart';
import 'render_scene.dart';

class TestRender03 implements RenderDelegate {
  final gl.RenderingContext _glContext;

  late final TestScene03 _scene;

  TestRender03(this._glContext) {
    _scene = TestScene03(_glContext);
  }

  @override
  void resize(int width, int height) {
    _glContext.viewport(0, 0, width, height);
    _scene.resize(width, height);
  }

  @override
  void render() {
    _glContext.enable(gl.WebGL.CULL_FACE);
    _glContext.cullFace(gl.WebGL.BACK);
    _glContext.frontFace(gl.WebGL.CCW);
    _glContext.enable(gl.WebGL.DEPTH_TEST);
    _glContext.clearColor(0.1, 0.1, 0.1, 1.0);
    _glContext.clear(gl.WebGL.COLOR_BUFFER_BIT | gl.WebGL.DEPTH_BUFFER_BIT);
    _scene.draw();
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

varying vec3 varPosition;

varying vec3 varNormal;

void main() {
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  varPosition = vec3(worldPosition) / worldPosition.w;
  varNormal = normalize(normalsMatrix * vec4(normal, 0.0)).xyz;
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

void main() {
  LightsIntensity light = lightsIntensity(
    varPosition, varNormal, cameraEyePosition, modelColorSpecular.w);
  vec3 diffuseColor = (light.ambient + light.diffuse) * modelColorDiffuse;
  vec3 specularColor = light.specular * modelColorSpecular.xyz;
  gl_FragColor = vec4(diffuseColor + specularColor, 1.0);
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

class TestScene03 {
  static final ZNear = 0.001;

  static final ZFar = 10.0;

  static final FovYDegrees = 75.0;

  static final FovYRadians = math.pi * FovYDegrees / 180.0;

  final gl.RenderingContext _glContext;

  final List<DisposableBuffers> _buffers;

  final TestProgram_03 _program;

  final List<RenderObject> _objects;

  final LightsData _lights;

  final Camera _camera;

  TestScene03._(
    this._glContext,
    this._buffers,
    this._program,
    this._objects,
    this._lights,
    this._camera);

  factory TestScene03(gl.RenderingContext glContext) {
    final disposableBuffers = <DisposableBuffers>[];

    late final TestProgram_03 program;
    try {
      program = TestProgram_03._(glContext);
    } on ProgramException catch (e) {
      print('${e.reason}\n${e.infoLog}');
      rethrow;
    }

    final cubeMeshData = CubeMeshData(glContext);
    disposableBuffers.add(cubeMeshData);

    final cellSize = 1.0;
    final avatarHeight = 1.5;

    final grid = GridGeometry(cellSize);

    final avatarEye = Vector3.zero();
    grid.calcTranslationVector(
      avatarEye, GridCoordinate(0, 0, 0), grid.cellSize);
    avatarEye.z += 3.0 * grid.cellSize;
    avatarEye.y += avatarHeight + grid.cellSize / 2.0;

    final objects = <RenderObject>[];

    Cube addCube(GridCoordinate coordinate) {
      final cube = Cube(cubeMeshData);
      grid.calcTranslationMatrix(cube.transform.modelMatrix, coordinate, 1.0);
      objects.add(cube);
      return cube;
    }

    // floor

    addCube(GridCoordinate(0, 0, 0));

    addCube(GridCoordinate(1, 0, 0));

    addCube(GridCoordinate(-1, 0, 0));

    addCube(GridCoordinate(0, -1, 0));

    addCube(GridCoordinate(1, -1, 0));

    addCube(GridCoordinate(-1, -1, 0));

    addCube(GridCoordinate(0, 1, 0));

    addCube(GridCoordinate(1, 1, 0));

    addCube(GridCoordinate(-1, 1, 0));

    // right wall

    addCube(GridCoordinate(1, 0, 1));

    addCube(GridCoordinate(1, 0, 2));

    addCube(GridCoordinate(1, 1, 1));

    addCube(GridCoordinate(1, 2, 1));

    addCube(GridCoordinate(1, 2, 2));

    addCube(GridCoordinate(1, 1, 3));

    // left wall

    addCube(GridCoordinate(-1, 0, 1));

    addCube(GridCoordinate(-1, 1, 2));

    addCube(GridCoordinate(-1, 2, 2));

    // ceiling

    addCube(GridCoordinate(0, 0, 3));

    addCube(GridCoordinate(0, 1, 3));

    addCube(GridCoordinate(0, 2, 3));

    final lights = LightsData();
    lights.ambientColor.setValues(0.2, 0.2, 0.2);
    /*lights.directLights.add(DirectLight()
      ..direction.setValues(0.0, 1.0, 0.0)
      ..color.setValues(0.3, 0.3, 0.3));*/
    lights.pointLights.add(PointLight()
      ..origin.setValues(
        avatarEye.x,
        avatarEye.y,
        avatarEye.z - 0.5)
      ..color.setValues(0.6, 0.3, 0.5));

    final camera = Camera();
    camera.setLookAt(
      avatarEye,
      Vector3.zero()..setValues(
        avatarEye.x,
        avatarEye.y,
        0.0),
      Vector3.zero()..setValues(0.0, 1.0, 0.0));

    return TestScene03._(
      glContext,
      disposableBuffers,
      program,
      objects,
      lights,
      camera);
  }

  void resize(int width, int height) {
    final aspectRatio = width / height;
    _camera.setPerspective(FovYRadians, aspectRatio, ZNear, ZFar);
  }

  void draw() {
    _program._viewProjectionMatrix.data = Matrix4UniformData(
      _camera.viewProjectionMatrix);
    _program._lightsBinding.data = _lights;
    _program._cameraEyePosition.data = Vector3UniformData(_camera.eyePosition);
    for (final object in _objects) {
      _drawObject(object);
    }
  }

  void _drawObject(RenderObject object) {
    _program._modelMatrix.data = object.modelMatrixData;
    _program._normalsMatrix.data = object.normalsMatrixData;
    _program._position.data = object.meshData.positionsData;
    _program._normal.data = object.meshData.normalsData;
    _program._modelColorDiffuse.data = Vector3UniformData(
      Vector3(0.2, 0.8, 0.5));
    _program._modelColorSpecular.data = Vector4UniformData(
      Vector4(0.0, 0.2, 0.0, 0.25));
    _program._indicesArray.data = object.meshData.indices;
    _program._program.draw();
  }

  void dispose() {
    _program._program.dispose();
    for (final disposable in _buffers) {
      disposable.disposeBuffers(_glContext);
    }
    _buffers.clear();
  }
}

class GridCoordinate {
  final int x;

  final int z;

  final int y;

  const GridCoordinate(this.x, this.z, this.y);

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
    Matrix4 mat, GridCoordinate coordinate, double objectSize) {
    coordinate.realWorldPoint(_tmp, cellSize, objectSize);
    mat.setTranslation(_tmp);
  }

  void calcTranslationVector(
    Vector3 vector, GridCoordinate coordinate, double objectSize) {
    coordinate.realWorldPoint(vector, cellSize, objectSize);
  }
}

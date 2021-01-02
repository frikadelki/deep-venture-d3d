import 'dart:math' as math;
import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';

import 'render_lights.dart';
import 'render_objects.dart';
import 'render_program.dart';
import 'render_root.dart';
import 'render_scene.dart';

class TestRender02 implements RenderDelegate {
  final gl.RenderingContext _glContext;

  late final TestScene_02 _scene;

  TestRender02(this._glContext) {
    _scene = TestScene_02(_glContext);
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

ProgramSource TestProgram_02_Source(LightsSnippet lights) => ProgramSource(
'TestProgram_02',

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
    varPosition, varNormal, cameraEyePosition.xyz, modelColorSpecular.w);
  vec3 diffuseColor = (light.ambient + light.diffuse) * modelColorDiffuse;
  vec3 specularColor = light.specular * modelColorSpecular.xyz;
  gl_FragColor = vec4(diffuseColor + specularColor, 1.0);
}
'''
);

class TestProgram_02  {
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

  TestProgram_02._(this._glContext) {
    final lightsSnippet = LightsSnippet(2);
    final source = TestProgram_02_Source(lightsSnippet);
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
  }

  set drawCalls(DrawCalls? calls) {
    _program.drawCalls = calls;
  }
}

class TestScene_02 {
  static final ZNear = 0.001;

  static final ZFar = 10.0;

  static final FovYDegrees = 110.0;

  static final FovYRadians = math.pi * FovYDegrees / 180.0;

  final gl.RenderingContext _glContext;

  final List<DisposableBuffers> _buffers;

  final TestProgram_02 _program;

  final List<RenderObject> _objects;

  final LightsData _lights;

  final Camera _camera;

  TestScene_02._(
    this._glContext,
    this._buffers,
    this._program,
    this._objects,
    this._lights,
    this._camera) {
    _program.drawCalls = CustomDrawCalls((glContext) {
      _program._indicesArray.drawAllTriangles();
    });
  }

  factory TestScene_02(gl.RenderingContext glContext) {
    final disposableBuffers = <DisposableBuffers>[];

    late final TestProgram_02 program;
    try {
      program = TestProgram_02._(glContext);
    } on ProgramException catch (e) {
      print('${e.reason}\n${e.infoLog}');
      rethrow;
    }

    final cubeMeshData = CubeMeshData(glContext);
    disposableBuffers.add(cubeMeshData);
    
    final cube1 = Cube(cubeMeshData);
    cube1.transform.translate(dx: 0.0, dy: -0.5, dz: -0.5);

    final cube2 = Cube(cubeMeshData);
    cube2.transform.translate(dx: 1.0, dy: 1.5, dz: -0.5);

    final cube3 = Cube(cubeMeshData);
    cube3.transform.translate(dx: -1.0, dy: 1.5, dz: -0.5);

    final cube4 = Cube(cubeMeshData);
    cube4.transform.translate(dx: 1.0, dy: 1.5, dz: 0.5);

    final cube5 = Cube(cubeMeshData);
    cube5.transform.translate(dx: 1.0, dy: 0.5, dz: 0.5);

    final cube6 = Cube(cubeMeshData);
    cube6.transform.translate(dx: 1.0, dy: 0.5, dz: -0.5);

    final cube7 = Cube(cubeMeshData);
    cube7.transform.translate(dx: 0.0, dy: 2.5, dz: -0.5);

    final cube8 = Cube(cubeMeshData);
    cube8.transform.translate(dx: -1.0, dy: 0.5, dz: 0.5);

    final lights = LightsData();
    lights.ambientColor.setValues(0.2, 0.2, 0.2);
    lights.directLights.add(DirectLight()
      ..direction.setValues(0.0, 1.0, 0.0)
      ..color.setValues(0.4, 0.4, 0.4));
    lights.pointLights.add(PointLight()
      ..origin.setValues(0.0, 1.7, 1.0)
      ..color.setValues(0.2, 0.2, 0.2));
    
    final camera = Camera();
    camera.setLookAt(
      Vector3.zero()..setValues(0.0, 1.7, 1.0),
      Vector3.zero()..setValues(0.0, 1.7, 0.0),
      Vector3.zero()..setValues(0.0, 1.0, 0.0));

    return TestScene_02._(
      glContext,
      disposableBuffers,
      program,
      [ cube1, cube2, cube3, cube4, cube5, cube6, cube7, cube8 ],
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
      Vector3(0.2, 0.7, 0.3));
    _program._modelColorSpecular.data = Vector4UniformData(
      Vector4(1.0, 1.0, 1.0, 20.0));
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

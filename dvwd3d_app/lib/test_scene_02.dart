import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';
import 'package:vector_math/vector_math_geometry.dart';

import 'render_geometry.dart';
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
    _glContext.clearColor(1.0, 0.5, 0.5, 1.0);
    _glContext.clear(gl.WebGL.COLOR_BUFFER_BIT | gl.WebGL.DEPTH_BUFFER_BIT);
    _scene.draw();
  }

  @override
  void dispose() {
    _scene.dispose();
  }
}

final TestProgram_01_Source = ProgramSource(
'TestProgram_01',

'''
uniform mat4 viewProjectionMatrix;

attribute vec3 position;

void main() {
  gl_Position = viewProjectionMatrix * vec4(position, 1.0);
}
''',

'''
void main() {
  gl_FragColor = vec4(0.5, 0.5, 0.7, 1.0);
}
'''
);

class TestScene_02 {
  final gl.RenderingContext _glContext;

  final List<gl.Buffer> _buffers;

  final Program _program;

  final Camera _camera;

  TestScene_02._(this._glContext, this._buffers, this._program, this._camera);

  factory TestScene_02(gl.RenderingContext glContext) {
    final buffers = <gl.Buffer>[ ];
    gl.Buffer createBuffer() {
      final buffer = glContext.createBuffer();
      buffers.add(buffer);
      return buffer;
    }

    final cubeGenerator = CubeGenerator();
    final cubeFlags = GeometryGeneratorFlags(texCoords: false, tangents: false);
    final cubeMesh = cubeGenerator.createCube(0.5, 0.5, 0.5, flags: cubeFlags);
    final cubeMeshAttributesBuffer = createBuffer();
    cubeMesh.bindAttributesData(glContext, cubeMeshAttributesBuffer);
    final cubeMeshIndicesBuffer = createBuffer();
    glContext.bindBuffer(gl.WebGL.ELEMENT_ARRAY_BUFFER, cubeMeshIndicesBuffer);
    glContext.bufferData(
      gl.WebGL.ELEMENT_ARRAY_BUFFER, cubeMesh.indices, gl.WebGL.STATIC_DRAW);

    final positionsAttributeData = cubeMesh.extractPositions(
      cubeMeshAttributesBuffer);

    final camera = Camera();
    camera.setLookAt(
      Vector3.zero()..setValues(0.0, 0.0,  0.0),
      Vector3.zero()..setValues(0.0, 0.0, -1.0),
      Vector3.zero()..setValues(0.0, 1.0,  0.0));

    final program = Program(glContext, TestProgram_01_Source);
    program.getUniform('viewProjectionMatrix').data = Matrix4UniformData(
      camera.viewProjectionMatrix);
    program.getVertexAttribute('position').data = positionsAttributeData;
    program.drawCalls = CustomDrawCalls((glContext) {
      glContext.bindBuffer(
        gl.WebGL.ELEMENT_ARRAY_BUFFER, cubeMeshIndicesBuffer);
      glContext.drawElements(
        gl.WebGL.TRIANGLES,
        cubeMesh.indices!.length ~/ 3,
        gl.WebGL.UNSIGNED_SHORT,
        0);
    });

    return TestScene_02._(glContext, buffers, program, camera);
  }

  void resize(int width, int height) {
    _camera.setOrthographic(width, height);
  }

  void draw() {
    _program.draw();
  }

  void dispose() {
    _program.dispose();
    for (final buffer in _buffers) {
      _glContext.deleteBuffer(buffer);
    }
    _buffers.clear();
  }
}

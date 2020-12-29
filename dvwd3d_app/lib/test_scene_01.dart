import 'dart:typed_data';
import 'dart:web_gl' as gl;

import 'package:dvwd3d_app/render_root.dart';

import 'render_program.dart';

class TestRender01 implements RenderDelegate {
  final gl.RenderingContext _glContext;

  late final TestScene_01 _scene;

  TestRender01(this._glContext) {
    _scene = TestScene_01(_glContext);
  }

  @override
  void resize(int width, int height) {
    _glContext.viewport(0, 0, width, height);
  }

  @override
  void render() {
    _glContext.clearColor(1.0, 0.5, 0.5, 1.0);
    _glContext.clear(gl.WebGL.COLOR_BUFFER_BIT);
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

attribute vec2 position;

void main() {
  gl_Position = vec4(position, 0.0, 1.0);
}

''',

'''

void main() {
  gl_FragColor = vec4(1.0, 0.5, 0.0, 1.0);
}

''');

final TrianglesVertices = Float32List.fromList([
  -0.5,  0.5,
   0.0, -0.5,
   0.5,  0.5,
]);

final TrianglesVAttributeSize = VertexAttributeSize.Two;

final TrianglesVAttributeDataType = VertexAttributeType.Float;

final TrianglesCount = TrianglesVertices.length ~/ TrianglesVAttributeSize.size;

class TestScene_01 {
  final gl.RenderingContext _glContext;

  final List<gl.Buffer> _buffers;

  final Program _program;

  TestScene_01._(this._glContext, this._buffers, this._program);

  factory TestScene_01(gl.RenderingContext glContext) {
    final buffers = <gl.Buffer>[ ];
    gl.Buffer createBuffer() {
      final buffer = glContext.createBuffer();
      buffers.add(buffer);
      return buffer;
    }

    VertexAttributeData makeTrianglesPositions() {
      final positionsVbo = createBuffer();
      glContext.bindBuffer(gl.WebGL.ARRAY_BUFFER, positionsVbo);
      glContext.bufferData(
        gl.WebGL.ARRAY_BUFFER, TrianglesVertices, gl.WebGL.STATIC_DRAW);
      return VertexAttributeData(
        positionsVbo, TrianglesVAttributeSize, TrianglesVAttributeDataType);
    }

    final program = Program(glContext, TestProgram_01_Source);
    program.getVertexAttribute('position').data = makeTrianglesPositions();
    program.drawCalls = DrawArraysTrianglesCall(TrianglesCount);

    return TestScene_01._(glContext, buffers, program);
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

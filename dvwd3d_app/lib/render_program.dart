import 'dart:web_gl' as gl;

class ProgramException implements Exception {
  final String reason;

  final String infoLog;

  ProgramException(this.reason, this.infoLog);
}

enum VertexAttributeType {
  Float,
}

extension on VertexAttributeType {
  int get glType {
    switch (this) {
      case VertexAttributeType.Float:
        return gl.WebGL.FLOAT;
    }
  }
}

enum VertexAttributeSize {
  One,
  Two,
  Three,
  Four,
}

extension VertexAttributeSizeExt on VertexAttributeSize {
  int get size {
    switch (this) {
      case VertexAttributeSize.One:
        return 1;

      case VertexAttributeSize.Two:
        return 2;

      case VertexAttributeSize.Three:
        return 3;

      case VertexAttributeSize.Four:
        return 4;
    }
  }
}

class VertexAttributeData {
  final gl.Buffer data;

  final VertexAttributeSize size;

  final VertexAttributeType type;

  final bool normalized;

  final int stride;

  final int offset;

  VertexAttributeData(
    this.data,
    this.size,
    this.type, {
    this.normalized = false,
    this.stride = 0,
    this.offset = 0,
    });
  
  void _bind(gl.RenderingContext glContext, int attributeIndex) {
    glContext.bindBuffer(gl.WebGL.ARRAY_BUFFER, data);
    glContext.vertexAttribPointer(
      attributeIndex, size.size, type.glType, normalized, stride, offset);
  }
}

class VertexAttribute {
  final gl.RenderingContext _glContext;

  final String name;

  final int _index;
  
  VertexAttributeData? data;

  VertexAttribute(this._glContext, this.name, this._index);

  void _enable() {
    final data = this.data;
    if (data == null) {
      return;
    }
    data._bind(_glContext, _index);
    _glContext.enableVertexAttribArray(_index);
  }
  
  void _disable() {
    _glContext.disableVertexAttribArray(_index);
  }
}

abstract class DrawCalls {
  void draw(gl.RenderingContext glContext);
}

class DrawArraysTrianglesCall implements DrawCalls {
  final int offset;

  final int count;

  DrawArraysTrianglesCall(this.count, { this.offset = 0 });

  @override
  void draw(gl.RenderingContext glContext) {
    glContext.drawArrays(gl.WebGL.TRIANGLES, offset, count);
  }
}

class ProgramSource {
  final String name;

  final String vertexShaderSource;

  final String fragmentShaderSource;

  ProgramSource(this.name, this.vertexShaderSource, this.fragmentShaderSource);
}

class Program {
  final gl.RenderingContext _glContext;

  final ProgramSource source;

  final _builder = _ProgramBuilder();

  final _vertexAttributes = <String, VertexAttribute>{ };
  
  DrawCalls? drawCalls;

  Program(this._glContext, this.source) {
    _builder.build(_glContext, source);
    assert(_builder.isReady);
  }

  VertexAttribute getVertexAttribute(String name) {
    _checkDisposed('Attempting to search for vertex attribute "$name".');
    return _vertexAttributes.putIfAbsent(name, () {
      final index = _glContext.getAttribLocation(_builder.program!, name);
      if (index < 0) {
        throw ArgumentError('No vertex attribute "$name".');
      }
      return VertexAttribute(_glContext, name, index);
    });
  }
  
  void draw() {
    _checkDisposed('Attempting to draw.');
    final drawCalls = this.drawCalls;
    if (drawCalls == null) {
      return;
    }
    _glContext.useProgram(_builder.program!);
    for (final attribute in _vertexAttributes.values) {
      attribute._enable();
    }
    drawCalls.draw(_glContext);
    for (final attribute in _vertexAttributes.values) {
      attribute._disable();
    }
  }

  void dispose() {
    _checkDisposed('Attempting to dispose.');
    _builder.dispose(_glContext);
    _vertexAttributes.clear();
  }

  void _checkDisposed([ String info = '<no info>' ]) {
    if (!_builder.isReady) {
      throw StateError('This program has been disposed of.\n$info');
    }
  }
}

class _ProgramBuilder {
  gl.Program? program;

  gl.Shader? vertexShader;

  gl.Shader? fragmentShader;

  bool get isReady => program != null;

  void build(gl.RenderingContext glContext, ProgramSource source) {
    if (isReady) {
      assert(false);
      dispose(glContext);
    }
    try {
      vertexShader = glContext._makeShader(
        _ShaderType.Vertex, source.vertexShaderSource);
      fragmentShader = glContext._makeShader(
        _ShaderType.Fragment, source.fragmentShaderSource);
      program = glContext.createProgram();
      glContext.attachShader(program!, vertexShader!);
      glContext.attachShader(program!, fragmentShader!);
      glContext.linkProgram(program!);
      final stats = glContext._getProgramStats(program!);
      if (!stats.linked) {
        throw ProgramException('Program linkage failed', stats.infoLog.log);
      } else if (stats.infoLog.hasInfo) {
        print('Program has info log after linkage:\n${stats.infoLog.log}');
      }
    } on ProgramException {
      dispose(glContext);
      rethrow;
    }
  }

  void dispose(gl.RenderingContext glContext) {
    if (program != null) {
      if (vertexShader != null) {
        glContext.detachShader(program!, vertexShader!);
      }
      if (fragmentShader != null) {
        glContext.detachShader(program!, fragmentShader!);
      }
      glContext.deleteProgram(program);
      program = null;
    }
    if (vertexShader != null) {
      glContext.deleteShader(vertexShader);
      vertexShader = null;
    }
    if (fragmentShader != null) {
      glContext.deleteShader(fragmentShader);
      fragmentShader = null;
    }
  }
}

enum _ShaderType {
  Vertex,
  Fragment,
}

extension on _ShaderType {
  int get glType {
    switch (this) {
      case _ShaderType.Vertex:
        return gl.WebGL.VERTEX_SHADER;

      case _ShaderType.Fragment:
        return gl.WebGL.FRAGMENT_SHADER;
    }
  }
}

class _InfoLog {
  final String? _content;

  _InfoLog(this._content);

  bool get hasInfo => _content != null && _content!.isNotEmpty;

  String get log => hasInfo ? _content! : '<no info>';
}

class _ShaderStats {
  final bool compiled;

  final _InfoLog infoLog;

  _ShaderStats(this.compiled, this.infoLog);
}

class _ProgramStats {
  final bool linked;

  final _InfoLog infoLog;

  _ProgramStats(this.linked, this.infoLog);
}

extension on gl.RenderingContext {
  _ShaderStats _getShaderStats(gl.Shader shader) {
    final compiled = getShaderParameter(shader, gl.WebGL.COMPILE_STATUS);
    final infoLogContent = getShaderInfoLog(shader);
    return _ShaderStats(compiled as bool, _InfoLog(infoLogContent));
  }

  gl.Shader _makeShader(_ShaderType type, String source) {
    final shader = createShader(type.glType);
    shaderSource(shader, source);
    compileShader(shader);
    final stats = _getShaderStats(shader);
    if (!stats.compiled) {
      deleteShader(shader);
      throw ProgramException('Shader compilation failed', stats.infoLog.log);
    } else if (stats.infoLog.hasInfo) {
      print('Shader has info log after compilation:\n${stats.infoLog.log}');
    }
    return shader;
  }

  _ProgramStats _getProgramStats(gl.Program program) {
    final linked = getProgramParameter(program, gl.WebGL.LINK_STATUS);
    final infoLogContent = getProgramInfoLog(program);
    return _ProgramStats(linked as bool, _InfoLog(infoLogContent));
  }
}


import 'dart:web_gl' as gl;

import 'package:dvwd3d_app/render_program.dart';
import 'package:vector_math/vector_math_geometry.dart';

extension MeshGeometryUtils on MeshGeometry {
  static const _A_NAME_POSITION = 'POSITION';
  static const _A_NAME_TEXCOORD0 = 'TEXCOORD0';
  static const _A_NAME_NORMAL = 'NORMAL';
  static const _A_NAME_TANGENT = 'TANGENT';
  
  static const _A_TYPE_FLOAT = 'float';
  
  void bindAttributesData(gl.RenderingContext glContext, gl.Buffer glBuffer) {
    glContext.bindBuffer(gl.WebGL.ARRAY_BUFFER, glBuffer);
    glContext.bufferData(
      gl.WebGL.ARRAY_BUFFER, buffer, gl.WebGL.STATIC_DRAW);
  }
  
  VertexAttributeData extractPositions(gl.Buffer buffer) {
    final attrib = getAttrib(_A_NAME_POSITION);
    if (attrib == null) {
      throw ArgumentError(
        'Mesh did not contain "$_A_NAME_POSITION" attribute.');
    }
    return _extract(buffer, attrib);
  }

  VertexAttributeData _extract(gl.Buffer buffer, VertexAttrib attrib) {
    return VertexAttributeData(
      buffer,
      VertexAttributeSizeExt.fromSize(attrib.size),
      _decodeType(attrib),
      offset: attrib.offset,
      stride: attrib.stride);
  }
  
  VertexAttributeType _decodeType(VertexAttrib attrib) {
    if (attrib.type != _A_TYPE_FLOAT) {
      throw ArgumentError(
        'Unknown type "${attrib.type}" for "${attrib.name}" attribute.');
    }
    return VertexAttributeType.Float;
  }
}

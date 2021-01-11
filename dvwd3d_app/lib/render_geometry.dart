
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
    final attribute = getAttrib(_A_NAME_POSITION);
    if (attribute == null) {
      throw ArgumentError(
        'Mesh did not contain "$_A_NAME_POSITION" attribute.');
    }
    return _extractAttribute(buffer, attribute);
  }

  VertexAttributeData extractNormals(gl.Buffer buffer) {
    final attribute = getAttrib(_A_NAME_NORMAL);
    if (attribute == null) {
      throw ArgumentError(
        'Mesh did not contain "$_A_NAME_NORMAL" attribute.');
    }
    return _extractAttribute(buffer, attribute);
  }

  VertexAttributeData extractTexCoord(gl.Buffer buffer) {
    final attribute = getAttrib(_A_NAME_TEXCOORD0);
    if (attribute == null) {
      throw ArgumentError(
        'Mesh did not contain "$_A_NAME_TEXCOORD0" attribute.');
    }
    return _extractAttribute(buffer, attribute);
  }

  VertexAttributeData _extractAttribute(
    gl.Buffer buffer, VertexAttrib attribute) {
    return VertexAttributeData(
      buffer,
      VertexAttributeSizeExt.fromSize(attribute.size),
      _decodeType(attribute),
      offset: attribute.offset,
      stride: attribute.stride);
  }
  
  VertexAttributeType _decodeType(VertexAttrib attrib) {
    if (attrib.type != _A_TYPE_FLOAT) {
      throw ArgumentError(
        'Unknown type "${attrib.type}" for "${attrib.name}" attribute.');
    }
    return VertexAttributeType.Float;
  }

  void bindIndicesData(gl.RenderingContext glContext, gl.Buffer buffer) {
    IndicesArrayData.setStaticDrawUi16L(glContext, buffer, indices!);
  }

  IndicesArrayData extractIndicesData(gl.Buffer buffer) {
    return IndicesArrayData(buffer, indices!.length);
  }
}

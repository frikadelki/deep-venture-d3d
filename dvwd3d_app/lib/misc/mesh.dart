import 'dart:web_gl' as gl;

import 'package:dvwd3d_app/engine/program.dart';
import 'package:vector_math/vector_math_geometry.dart';

import 'utils.dart';

abstract class MeshData {
  VertexAttributeData get positionsData;

  VertexAttributeData get normalsData;

  VertexAttributeData get texCoordData;

  IndicesArrayData get indices;
}

class CubeMeshData implements MeshData, DisposableBuffers {
  final gl.Buffer _attributesGlBuffer;

  @override
  final VertexAttributeData positionsData;

  @override
  final VertexAttributeData normalsData;

  @override
  final VertexAttributeData texCoordData;

  final gl.Buffer _indicesGlBuffer;

  @override
  final IndicesArrayData indices;

  CubeMeshData._(
    this._attributesGlBuffer,
    this.positionsData,
    this.normalsData,
    this.texCoordData,
    this._indicesGlBuffer,
    this.indices);

  factory CubeMeshData.cube(gl.RenderingContext glContext, double size) {
    final hSize = size / 2.0;
    final cubeGenerator = CubeGenerator();
    final cubeFlags = GeometryGeneratorFlags(
      texCoords: true, normals: true, tangents: false);
    final mesh = cubeGenerator.createCube(
      hSize, hSize, hSize, flags: cubeFlags);

    final attributesBuffer = glContext.createBuffer();
    mesh.bindAttributesData(glContext, attributesBuffer);
    final positionsData = mesh.extractPositions(attributesBuffer);
    final normalsData = mesh.extractNormals(attributesBuffer);
    final texCoordData = mesh.extractTexCoord(attributesBuffer);

    final indicesBuffer = glContext.createBuffer();
    mesh.bindIndicesData(glContext, indicesBuffer);
    final indicesData = mesh.extractIndicesData(indicesBuffer);

    return CubeMeshData._(
      attributesBuffer,
      positionsData,
      normalsData,
      texCoordData,
      indicesBuffer,
      indicesData);
  }

  @override
  void disposeBuffers(gl.RenderingContext glContext) {
    glContext.deleteBuffer(_attributesGlBuffer);
    glContext.deleteBuffer(_indicesGlBuffer);
  }
}

class CylinderMeshData implements MeshData, DisposableBuffers {
  final gl.Buffer _attributesGlBuffer;

  @override
  final VertexAttributeData positionsData;

  @override
  final VertexAttributeData normalsData;

  @override
  final VertexAttributeData texCoordData;

  final gl.Buffer _indicesGlBuffer;

  @override
  final IndicesArrayData indices;

  CylinderMeshData._(
    this._attributesGlBuffer,
    this.positionsData,
    this.normalsData,
    this.texCoordData,
    this._indicesGlBuffer,
    this.indices);

  factory CylinderMeshData.coin(
    gl.RenderingContext glContext, double radius, double thickness) {
    final cylinderGenerator = CylinderGenerator();
    final flags = GeometryGeneratorFlags(
      texCoords: true, normals: true, tangents: false);
    final mesh = cylinderGenerator.createCylinder(
      radius, radius, thickness, segments: 32, flags: flags);

    final attributesBuffer = glContext.createBuffer();
    mesh.bindAttributesData(glContext, attributesBuffer);
    final positionsData = mesh.extractPositions(attributesBuffer);
    final normalsData = mesh.extractNormals(attributesBuffer);
    final texCoordData = mesh.extractTexCoord(attributesBuffer);

    final indicesBuffer = glContext.createBuffer();
    mesh.bindIndicesData(glContext, indicesBuffer);
    final indicesData = mesh.extractIndicesData(indicesBuffer);

    return CylinderMeshData._(
      attributesBuffer,
      positionsData,
      normalsData,
      texCoordData,
      indicesBuffer,
      indicesData);
  }

  @override
  void disposeBuffers(gl.RenderingContext glContext) {
    glContext.deleteBuffer(_attributesGlBuffer);
    glContext.deleteBuffer(_indicesGlBuffer);
  }
}

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

  VertexAttributeData extractTangents(gl.Buffer buffer) {
    final attribute = getAttrib(_A_NAME_TANGENT);
    if (attribute == null) {
      throw ArgumentError(
        'Mesh did not contain "$_A_NAME_TANGENT" attribute.');
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

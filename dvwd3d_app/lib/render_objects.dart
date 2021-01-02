import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';
import 'package:vector_math/vector_math_geometry.dart';

import 'render_geometry.dart';
import 'render_program.dart';

abstract class DisposableBuffers {
  void disposeBuffers(gl.RenderingContext glContext);
}

abstract class MeshData {
  VertexAttributeData get positionsData;

  VertexAttributeData get normalsData;

  IndicesArrayData get indices;
}

abstract class RenderObject {
  Matrix4UniformData get modelMatrixData;

  Matrix4UniformData get normalsMatrixData;

  MeshData get meshData;
}

class CubeMeshData implements MeshData, DisposableBuffers {
  final gl.Buffer _attributesGlBuffer;

  @override
  final VertexAttributeData positionsData;

  @override
  final VertexAttributeData normalsData;

  final gl.Buffer _indicesGlBuffer;

  @override
  final IndicesArrayData indices;

  CubeMeshData._(
    this._attributesGlBuffer,
    this.positionsData,
    this.normalsData,
    this._indicesGlBuffer,
    this.indices);

  factory CubeMeshData(gl.RenderingContext glContext) {
    final cubeGenerator = CubeGenerator();
    final cubeFlags = GeometryGeneratorFlags(
      texCoords: false, normals: true, tangents: false);
    final mesh = cubeGenerator.createCube(0.5, 0.5, 0.5, flags: cubeFlags);

    final attributesBuffer = glContext.createBuffer();
    mesh.bindAttributesData(glContext, attributesBuffer);
    final positionsData = mesh.extractPositions(attributesBuffer);
    final normalsData = mesh.extractNormals(attributesBuffer);

    final indicesBuffer = glContext.createBuffer();
    mesh.bindIndicesData(glContext, indicesBuffer);
    final indicesData = mesh.extractIndicesData(indicesBuffer);

    return CubeMeshData._(
      attributesBuffer, positionsData, normalsData, indicesBuffer, indicesData);
  }

  @override
  void disposeBuffers(gl.RenderingContext glContext) {
    glContext.deleteBuffer(_attributesGlBuffer);
    glContext.deleteBuffer(_indicesGlBuffer);
  }
}

class Transform {
  final modelMatrix = Matrix4.identity();

  final normalsMatrix = Matrix4.identity();

  void translate({double dx = 0.0, double dy = 0.0, double dz = 0.0}) {
    modelMatrix.translate(dx, dy, dz);
  }
}

class Cube implements RenderObject {
  final transform = Transform();

  @override
  late final Matrix4UniformData modelMatrixData;

  @override
  late final Matrix4UniformData normalsMatrixData;

  @override
  final CubeMeshData meshData;

  Cube(this.meshData) {
    modelMatrixData = Matrix4UniformData(transform.modelMatrix);
    normalsMatrixData = Matrix4UniformData(transform.normalsMatrix);
  }
}

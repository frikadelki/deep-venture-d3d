
import 'package:vector_math/vector_math.dart';

import 'render_program.dart';

class Camera {
  final _viewMatrix = Matrix4.identity();

  final _projectionMatrix = Matrix4.identity();

  final _eyePosition = Vector3.zero();

  Vector3 get eyePosition => _eyePosition;

  final _computedViewProjectionMatrix = Matrix4.identity();

  Matrix4 get viewProjectionMatrix => _computedViewProjectionMatrix;

  void _updateViewProjection() {
    _computedViewProjectionMatrix
      ..setFrom(_projectionMatrix)
      ..multiply(_viewMatrix);
  }

  void setLookAt(Vector3 eyePosition, Vector3 lookAtCenter, Vector3 cameraUp) {
    _eyePosition.setFrom(eyePosition);
    setViewMatrix(_viewMatrix, eyePosition, lookAtCenter, cameraUp);
    _updateViewProjection();
  }

  void setOrthographic(int viewportWidth, int viewportHeight) {
    final WorldWH = 1.0;
    final ZNear = 1.0;
    final ZFar = 2.0;

    final aspectRatio = viewportWidth / viewportHeight;
    late final double worldWidth;
    late final double worldHeight;
    if (viewportWidth < viewportHeight) {
      worldWidth = WorldWH;
      worldHeight = worldWidth / aspectRatio;
    } else {
      worldHeight = WorldWH;
      worldWidth = worldHeight * aspectRatio;
    }
    setOrthographicMatrix(
      _projectionMatrix,
      -worldWidth,
      worldWidth,
      -worldHeight,
      worldHeight,
      ZNear,
      ZFar);
    _updateViewProjection();
  }

  void setPerspective(
    double fovYRadians, double whAspectRatio, double zNear, double zFar) {
    setPerspectiveMatrix(
      _projectionMatrix,
      fovYRadians,
      whAspectRatio,
      zNear,
      zFar);
    _updateViewProjection();
  }
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

class Transform {
  final modelMatrix = Matrix4.identity();

  final normalsMatrix = Matrix4.identity();

  void translate({double dx = 0.0, double dy = 0.0, double dz = 0.0}) {
    modelMatrix.translate(dx, dy, dz);
  }
}


import 'package:vector_math/vector_math.dart';

class Camera {
  static const FovYDegrees = 90.0;

  final _viewMatrix = Matrix4.identity();

  final _projectionMatrix = Matrix4.identity();

  final _eyePosition = Vector3.zero();

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
    final ZNear = -0.99;
    final ZFar = 1.0;

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
}

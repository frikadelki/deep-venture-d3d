
import 'package:vector_math/vector_math.dart';

class GridVector {
  final int x;

  final int z;

  final int y;

  const GridVector(this.x, this.z, this.y);

  factory GridVector.zero() {
    return const GridVector(0, 0, 0);
  }

  GridVector add(GridVector d) {
    return GridVector(x + d.x, z + d.z, y + d.y);
  }

  void realWorldPoint(Vector3 translation, double cellSize, double objectSize) {
    final dSize = objectSize / 2.0;
    translation.setValues(
      x * cellSize + dSize,
      y * cellSize + dSize,
      z * cellSize + dSize);
  }
}

class GridGeometry {
  final double cellSize;

  final _tmp = Vector3.zero();

  GridGeometry(this.cellSize);

  void calcTranslationMatrix(
    Matrix4 mat, GridVector coordinate, double objectSize) {
    coordinate.realWorldPoint(_tmp, cellSize, objectSize);
    mat.setTranslation(_tmp);
  }

  void calcTranslationVector(
    Vector3 vector, GridVector coordinate, [ double? objectSize ]) {
    coordinate.realWorldPoint(vector, cellSize, objectSize ?? cellSize);
  }
}

enum GridRotation {
  Right,
  Left,
}

enum GridAbsoluteDirection {
  North,
  East,
  South,
  West,
}

class GridAbsoluteDirectionMeta {
  final GridVector gridVector;

  final Vector3 worldVector;

  final GridAbsoluteDirection opposite;

  final GridAbsoluteDirection right;

  final GridAbsoluteDirection left;

  GridAbsoluteDirectionMeta(
    this.gridVector, this.worldVector, this.opposite, this.right, this.left);
}

extension GridAbsoluteDirectionExt on GridAbsoluteDirection {
  static final _NorthMeta = GridAbsoluteDirectionMeta(
    GridVector(0, -1, 0),
    Vector3(0.0, 0.0, -1.0),
    GridAbsoluteDirection.South,
    GridAbsoluteDirection.East,
    GridAbsoluteDirection.West);

  static final _EastMeta = GridAbsoluteDirectionMeta(
    GridVector(1, 0, 0),
    Vector3(1.0, 0.0, 0.0),
    GridAbsoluteDirection.West,
    GridAbsoluteDirection.South,
    GridAbsoluteDirection.North);

  static final _SouthMeta = GridAbsoluteDirectionMeta(
    GridVector(0, 1, 0),
    Vector3(0.0, 0.0, 1.0),
    GridAbsoluteDirection.North,
    GridAbsoluteDirection.West,
    GridAbsoluteDirection.East);

  static final _WestMeta = GridAbsoluteDirectionMeta(
    GridVector(-1, 0, 0),
    Vector3(-1.0, 0.0, 0.0),
    GridAbsoluteDirection.East,
    GridAbsoluteDirection.North,
    GridAbsoluteDirection.South);

  GridAbsoluteDirectionMeta get meta {
    switch (this) {
      case GridAbsoluteDirection.North:
        return _NorthMeta;

      case GridAbsoluteDirection.East:
        return _EastMeta;

      case GridAbsoluteDirection.South:
        return _SouthMeta;

      case GridAbsoluteDirection.West:
        return _WestMeta;
    }
  }

  GridVector get gridVector {
    return meta.gridVector;
  }

  Vector3 get worldVector {
    return meta.worldVector;
  }

  GridAbsoluteDirection relative(GridRelativeDirection relation) {
    switch (relation) {
      case GridRelativeDirection.Forward:
        return this;

      case GridRelativeDirection.Right:
        return meta.right;

      case GridRelativeDirection.Backward:
        return meta.opposite;

      case GridRelativeDirection.Left:
        return meta.left;
    }
  }

  GridAbsoluteDirection rotate(GridRotation rotation) {
    switch (rotation) {
      case GridRotation.Right:
        return meta.right;

      case GridRotation.Left:
        return meta.left;
    }
  }
}

enum GridRelativeDirection {
  Forward,
  Right,
  Backward,
  Left,
}

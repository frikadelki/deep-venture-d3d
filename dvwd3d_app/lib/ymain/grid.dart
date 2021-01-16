import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';

import '../engine/lights.dart';
import '../engine/program.dart';
import '../misc/mesh.dart';
import '../misc/scene.dart';
import 'grid_geometry.dart';

class Voxel {
  final _modelMatrixUD = Matrix4UniformData.auto();

  Voxel();
}

class Grid {
  final GridGeometry _geometry;

  final CubeMeshData _voxelMeshData;

  final _colorDiffuseUD = Vector3UniformData.auto();

  final _colorSpecularUD = Vector4UniformData.auto();

  final _voxels = <Voxel>[];

  Grid(
    this._geometry,
    this._voxelMeshData,
    Vector3 colorDiffuse,
    Vector4 colorSpecular) {
    _colorDiffuseUD.data.setFrom(colorDiffuse);
    _colorSpecularUD.data.setFrom(colorSpecular);
  }

  void importLayer(List<List<int>> data, int y) {
    for (var row = 0; row < data.length; row++) {
      final rowData = data[row];
      for (var column = 0; column < rowData.length; column++) {
        final value = rowData[column];
        if (value <= 0) {
          continue;
        }
        final coordinate = GridVector(row, -column, y);
        final voxel = Voxel();
        _geometry.calcTranslationMatrix(
          voxel._modelMatrixUD.matrix, coordinate, _geometry.cellSize);
        _voxels.add(voxel);
      }
    }
  }
}

class GridProgram {
  final gl.RenderingContext _glContext;

  late final Program _program;

  late final LightsBinding _lightsBinding;

  late final Uniform _cameraEyePosition;

  late final Uniform _viewProjectionMatrix;

  late final Uniform _modelMatrix;

  late final Uniform _normalsMatrix;

  late final VertexAttribute _position;

  late final VertexAttribute _normal;

  late final VertexAttribute _texCoord;

  late final Uniform _modelColorDiffuse;

  late final Uniform _modelColorSpecular;

  late final IndicesArray _indicesArray;

  GridProgram(this._glContext, int lightCount) {
    final lightsSnippet = LightsSnippet(lightCount);
    final source = _ProgramSource(lightsSnippet);
    _program = Program(_glContext, source);
    _lightsBinding = lightsSnippet.makeBinding(_program);
    _cameraEyePosition = _program.getUniform('cameraEyePosition');
    _viewProjectionMatrix = _program.getUniform('viewProjectionMatrix');
    _modelMatrix = _program.getUniform('modelMatrix');
    _normalsMatrix = _program.getUniform('normalsMatrix');
    _position = _program.getVertexAttribute('position');
    _normal = _program.getVertexAttribute('normal');
    _texCoord = _program.getVertexAttribute('texCoord');
    _modelColorDiffuse = _program.getUniform('modelColorDiffuse');
    _modelColorSpecular = _program.getUniform('modelColorSpecular');
    _indicesArray = IndicesArray(_glContext);
    _program.drawCalls = CustomDrawCalls((glContext) {
      _indicesArray.drawAllTriangles();
    });
  }

  void setup(LightsData lights, Camera camera) {
    _lightsBinding.data = lights;
    _cameraEyePosition.data = Vector3UniformData(camera.eyePosition);
    _viewProjectionMatrix.data = Matrix4UniformData(
      camera.viewProjectionMatrix);
  }

  void draw(Grid grid) {
    _modelColorDiffuse.data = grid._colorDiffuseUD;
    _modelColorSpecular.data = grid._colorSpecularUD;
    final meshData = grid._voxelMeshData;
    _position.data = meshData.positionsData;
    _normal.data = meshData.normalsData;
    _texCoord.data = meshData.texCoordData;
    _indicesArray.data = meshData.indices;
    _normalsMatrix.data = Matrix4UniformData(Matrix4.identity());
    for (final voxel in grid._voxels) {
      _modelMatrix.data = voxel._modelMatrixUD;
      _program.draw();
    }
  }

  void dispose() {
    _program.dispose();
  }
}

ProgramSource _ProgramSource(LightsSnippet lights) => ProgramSource(
'GridProgram',

'''
precision mediump float;

uniform mat4 viewProjectionMatrix;

uniform mat4 modelMatrix;

uniform mat4 normalsMatrix;

attribute vec3 position;

attribute vec3 normal;

attribute vec2 texCoord;

varying vec3 varPosition;

varying vec3 varNormal;

varying vec2 varTexCoord;

void main() {
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  varPosition = vec3(worldPosition) / worldPosition.w;
  varNormal = normalize(normalsMatrix * vec4(normal, 0.0)).xyz;
  varTexCoord = texCoord;
  gl_Position = viewProjectionMatrix * worldPosition;
}
''',

'''
precision mediump float;

${lights.source}

uniform vec3 cameraEyePosition;

uniform vec3 modelColorDiffuse;

uniform vec4 modelColorSpecular;

varying vec3 varPosition;

varying vec3 varNormal;

varying vec2 varTexCoord;

const float TCD_THRESHOLD = 0.02;

void main() {
  LightsIntensity light = lightsIntensity(
    varPosition, varNormal, cameraEyePosition, modelColorSpecular.w);
  vec3 diffuseColor = (light.ambient + light.diffuse) * modelColorDiffuse;
  vec3 specularColor = light.specular * modelColorSpecular.xyz;
  float tcdx = 0.5 - abs(varTexCoord.x - 0.5);
  float tcdy = 0.5 - abs(varTexCoord.y - 0.5);
  float tcdMin = min(tcdx, tcdy);
  float attune = 1.0;
  if (tcdMin <= TCD_THRESHOLD) {
    attune = 0.4 + 0.6 * tcdMin / TCD_THRESHOLD;
  }
  vec3 color = attune * (diffuseColor + specularColor);
  gl_FragColor = vec4(color, 1.0);
}
'''
);

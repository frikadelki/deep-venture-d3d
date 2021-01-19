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

  late final VertexAttribute _tangentsInfo;

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
    _tangentsInfo = _program.getVertexAttribute('tangentsInfo');
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
    _tangentsInfo.data = meshData.tangentsInfoData;
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

// vec4 bitangent = cross(normal, tangent.xyz) * tangent.w
attribute vec4 tangentsInfo;

varying vec3 varPosition;

varying vec3 varNormal;

varying vec2 varTexCoord;

varying mat3 varTBN;

void main() {
  vec3 tangent = tangentsInfo.xyz;
  vec3 bitangent = cross(normal, tangent) * tangentsInfo.w;
  vec3 T = normalize(vec3(normalsMatrix * vec4(tangent,   0.0)));
  vec3 B = normalize(vec3(normalsMatrix * vec4(bitangent, 0.0)));
  vec3 N = normalize(vec3(normalsMatrix * vec4(normal,    0.0)));
  varTBN = mat3(T, B, N);

  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  varPosition = vec3(worldPosition) / worldPosition.w;
  varNormal = normalize(normalsMatrix * vec4(normal, 0.0)).xyz;
  varTexCoord = texCoord;
  gl_Position = viewProjectionMatrix * worldPosition;
}
''',

'''
precision mediump float;

const float pi = 3.1415926535897932384626433832795;

${lights.source}

uniform vec3 cameraEyePosition;

uniform vec3 modelColorDiffuse;

uniform vec4 modelColorSpecular;

varying vec3 varPosition;

varying vec3 varNormal;

varying vec2 varTexCoord;

varying mat3 varTBN;

const float TCD_THRESHOLD = 0.02;

const float ffScale = 0.25 * 0.25;

const float ffPeriod = 4.0;

const float ffXOffset = 0.125;

const float ffYOffset = 0.25;

float ffValue(float xx, float yy) {
  float fValue = 
    sin(ffPeriod * pi * (xx - ffXOffset)) + 
    cos(ffPeriod * pi * (yy - ffYOffset)) +
    2.0;
  return fValue * ffScale;
}

vec3 ffNormal(float xx, float yy) {
  vec3 vv1dx = vec3(
    1.0, 
    0.0, 
    ffScale * ffPeriod * pi * cos(ffPeriod * pi * (xx - ffXOffset))
    );
  vec3 vv2dy = vec3(
    0.0, 
    1.0, 
    ffScale * ffPeriod * pi * -sin(ffPeriod * pi * (yy - ffYOffset))
    );
  return normalize(cross(vv1dx, vv2dy));
}

void main() {
  float ffx = varTexCoord.x;
  float ffy = varTexCoord.y;
  float fValue = ffValue(ffx, ffy);
  vec3 fPositionShift = varTBN * vec3(0.0, 0.0, fValue);
  vec3 fPosition = varPosition + fPositionShift;
  vec3 fNormal = ffNormal(ffx, ffy);
  fNormal = normalize(varTBN * fNormal);
  
  vec3 fixedDiffuseColor = vec3(
    modelColorDiffuse.r + fValue * 3.0,
    modelColorDiffuse.g + fValue, 
    modelColorDiffuse.b + fValue * 3.0);
  vec3 fixedSpecularColor = vec3(
    modelColorSpecular.r + fValue * 3.0,
    modelColorSpecular.g + fValue, 
    modelColorSpecular.b + fValue * 3.0);
  
  LightsIntensity light = lightsIntensity(
    fPosition,
    fNormal, 
    cameraEyePosition, 
    modelColorSpecular.w);
  vec3 diffuseColor = (light.ambient + light.diffuse) * fixedDiffuseColor;
  vec3 specularColor = light.specular * fixedSpecularColor;
  
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

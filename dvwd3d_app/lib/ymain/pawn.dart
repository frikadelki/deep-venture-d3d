import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';

import '../engine/lights.dart';
import '../engine/program.dart';
import '../misc/mesh.dart';
import '../misc/scene.dart';
import 'grid_geometry.dart';

class GridPawn {
  final GridGeometry _gridGeometry;

  final transform = Transform();

  late final Matrix4UniformData _modelMatrixData;

  late final Matrix4UniformData _normalsMatrixData;

  final MeshData meshData;

  final _colorDiffuseUD = Vector3UniformData.auto();

  final _colorSpecularUD = Vector4UniformData.auto();

  GridPawn(
    this._gridGeometry,
    this.meshData,
    Vector3 colorDiffuse,
    Vector4 colorSpecular) {
    _modelMatrixData = Matrix4UniformData(transform.modelMatrix);
    _normalsMatrixData = Matrix4UniformData(transform.normalsMatrix);
    _colorDiffuseUD.data.setFrom(colorDiffuse);
    _colorSpecularUD.data.setFrom(colorSpecular);

    moveTo(GridVector.zero());
  }

  void moveTo(GridVector coordinate) {
    final tmp = Vector3.zero();
    _gridGeometry.calcTranslationVector(tmp, coordinate, 1.0);
    transform.setTranslation(tmp);
  }
}

class PawnProgram {
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

  PawnProgram(this._glContext, int lightCount) {
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

  void draw(GridPawn pawn) {
    final meshData = pawn.meshData;
    _position.data = meshData.positionsData;
    _normal.data = meshData.normalsData;
    _texCoord.data = meshData.texCoordData;
    _indicesArray.data = meshData.indices;
    _modelColorDiffuse.data = pawn._colorDiffuseUD;
    _modelColorSpecular.data = pawn._colorSpecularUD;
    _modelMatrix.data = pawn._modelMatrixData;
    _normalsMatrix.data = pawn._normalsMatrixData;
    _program.draw();
  }

  void dispose() {
    _program.dispose();
  }
}

ProgramSource _ProgramSource(LightsSnippet lights) => ProgramSource(
'PawnProgram',

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
  vec3 color = (diffuseColor + specularColor);
  gl_FragColor = vec4(color, 1.0);
}
'''
);

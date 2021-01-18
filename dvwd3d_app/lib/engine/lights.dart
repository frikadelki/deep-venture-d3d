
import 'package:vector_math/vector_math.dart';
import 'package:vector_math/vector_math_lists.dart';

import 'program.dart';

class DirectLight {
  final color = Vector3.zero();

  final direction = Vector3.zero();
}

class PointLight {
  final color = Vector3.zero();

  double fadeK = 1.0;

  final origin = Vector3.zero();
}

class LightsData {
  final ambientColor = Vector3.zero();

  final directLights = <DirectLight>[];

  final pointLights = <PointLight>[];
}

class LightsBinding {
  final int _simpleLightsCount;

  final Uniform _ambientColor;

  final Uniform _simpleLightsSpecs;

  final Uniform _simpleLightsColors;

  late final _LightsExporter _exporter;

  LightsBinding._(
    this._simpleLightsCount,
    this._ambientColor,
    this._simpleLightsSpecs,
    this._simpleLightsColors) {
    _exporter = _LightsExporter(_simpleLightsCount);
  }

  set data(LightsData? data) {
    if (data != null) {
      _exporter.rebuild(data.directLights, data.pointLights);
    } else {
      _exporter.clear();
    }
    _bind(data?.ambientColor ?? Vector3.zero());
  }

  void _bind(Vector3 ambientColorValue) {
    _ambientColor.data = Vector3UniformData(ambientColorValue);
    _simpleLightsSpecs.data = Vector4ListUniformData(
      _exporter.simpleLightsSpecs);
    _simpleLightsColors.data = Vector4ListUniformData(
      _exporter.simpleLightsColors);
  }
}

class _LightsExporter {
  final int simpleLightsCount;

  late final Vector4List simpleLightsSpecs;

  late final Vector4List simpleLightsColors;

  _LightsExporter(this.simpleLightsCount) {
    simpleLightsSpecs = Vector4List(simpleLightsCount);
    simpleLightsColors = Vector4List(simpleLightsCount);
  }
  
  void clear() {
    rebuild([], []);
  }

  void rebuild(List<DirectLight> directs, List<PointLight> points) {
    if (directs.length + points.length > simpleLightsCount) {
      assert(false);
    }
    var lightIndex = 0;
    void addLight(Vector4 spec, Vector4 color) {
      if (lightIndex >= simpleLightsCount) {
        assert(false);
        return;
      }
      simpleLightsSpecs[lightIndex] = spec;
      simpleLightsColors[lightIndex] = color;
      lightIndex++;
    }
    void addOff() {
      addLight(Vector4(0.0, 0.0, 0.0, _SPEC_W_OFF), Vector4.zero());
    }
    void addDirect(DirectLight direct) {
      final spec = Vector4(
        direct.direction.x,
        direct.direction.y,
        direct.direction.z,
        _SPEC_W_DIRECTED);
      final color = Vector4(
        direct.color.x,
        direct.color.y,
        direct.color.z,
        0.0);
      addLight(spec, color);
    }
    void addPoint(PointLight point) {
      final spec = Vector4(
        point.origin.x,
        point.origin.y,
        point.origin.z,
        _SPEC_W_POINT);
      final color = Vector4(
        point.color.x,
        point.color.y,
        point.color.z,
        point.fadeK);
      addLight(spec, color);
    }
    for (final direct in directs) {
      addDirect(direct);
    }
    for (final point in points) {
      addPoint(point);
    }
    while (lightIndex < simpleLightsCount) {
      addOff();
    }
  }
}

class LightsSnippet {
  final int simpleLightsCount;

  LightsSnippet(this.simpleLightsCount) : assert (simpleLightsCount > 0);

  String get source => _makeSnippetSource(simpleLightsCount);

  LightsBinding makeBinding(ProgramVarsLocator locator) {
    final ambientColor = locator.getUniform(_U_AMBIENT);
    final simpleLightsSpecs = locator.getUniform(_U_SIMPLE_LIGHTS_SPECS);
    final simpleLightsColors = locator.getUniform(_U_SIMPLE_LIGHTS_COLORS);
    return LightsBinding._(
      simpleLightsCount,
      ambientColor,
      simpleLightsSpecs,
      simpleLightsColors);
  }
}

const _U_AMBIENT = 'lightsAmbient';

const _U_SIMPLE_LIGHTS_SPECS = 'lightsSimpleSpec';

const _U_SIMPLE_LIGHTS_COLORS = 'lightsSimpleColor';

// this light is off
const _SPEC_W_OFF = 0.1;

// this is a directed light
// xyz determine direction
const _SPEC_W_DIRECTED = 1.1;

// this is a point light
// xyz determine source position
const _SPEC_W_POINT = 2.1;

String _makeSnippetSource(int maxSimpleLights) =>
'''
uniform vec3 lightsAmbient;

// w component determines type of light
uniform vec4 lightsSimpleSpec[$maxSimpleLights];

uniform vec4 lightsSimpleColor[$maxSimpleLights];

struct LightsIntensity {
  vec3 ambient;
  vec3 diffuse;
  vec3 specular;
};

LightsIntensity lightsIntensity(vec3 position, vec3 normal, vec3 eye, float shininess) {
  normal = normalize(normal);
  LightsIntensity light = LightsIntensity(lightsAmbient, vec3(0.0), vec3(0.0));
  for(int i = 0; i < $maxSimpleLights; i++) {
    vec4 lightSpec = lightsSimpleSpec[i];
    vec4 colorSpec = lightsSimpleColor[i];
    float fade = 1.0;
    vec3 lightDirection;
    if (lightSpec.w == $_SPEC_W_DIRECTED) {
      lightDirection = normalize(lightSpec.xyz);
    } else if (lightSpec.w == $_SPEC_W_POINT) {
      lightDirection = lightSpec.xyz - position;
      float distance = length(lightDirection);
      lightDirection = normalize(lightDirection);
      fade = 1.0 + distance * distance * colorSpec.a;
    } else {
      // supposed to be (lightSpec.w == $_SPEC_W_OFF)
      // but we turn if off anyhow
      continue;
    }
    float lambertian = dot(lightDirection, normal);
    if (lambertian <= 0.0) {
      continue;
    }
    vec3 viewDirection = normalize(eye - position);
    vec3 lightViewHalf = normalize(lightDirection + viewDirection);
    float specularAngle = dot(lightViewHalf, normal);
    float specularPower = pow(max(0.0, specularAngle), shininess);
    vec3 lightColor = colorSpec.rgb / fade;
    light.diffuse += lambertian * lightColor;
    light.specular += specularPower * lightColor;
  }
  return light;
}
''';

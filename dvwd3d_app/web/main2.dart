import 'dart:html' as html;
import 'dart:web_gl' as gl;

import 'package:dvwd3d_app/render_root.dart';
import 'package:dvwd3d_app/test_scene_01.dart';
import 'package:dvwd3d_app/test_scene_02.dart';
import 'package:dvwd3d_app/test_scene_03.dart';

void main() {
  html.CanvasElement findCanvas(String selectors) {
    final element = html.document.querySelector(selectors);
    return element as html.CanvasElement;
  }
  final canvas = findCanvas('#main-render-canvas');
  //runRenderOnCanvas(canvas, (glContext) => TestRender01(glContext));
  //runRenderOnCanvas(canvas, (glContext) => TestRender02(glContext));
  runRenderOnCanvas(canvas, (glContext) => TestScene_03_Delegate(glContext));
}

void runRenderOnCanvas(
  html.CanvasElement canvas,
  SceneDelegate Function(gl.RenderingContext) sceneFactory) {
  final glContext = canvas.getContext3d();
  final delegate = sceneFactory(glContext);

  void resize() {
    final cssPixelsWidth = canvas.clientWidth;
    final cssPixelsHeight = canvas.clientHeight;

    canvas.width = cssPixelsWidth;
    canvas.height = cssPixelsHeight;

    delegate.resize(cssPixelsWidth, cssPixelsHeight);
  }
  canvas.onResize.forEach((element) {
    resize();
  });
  resize();

  void onAnimationFrame(num timestamp) {
    delegate.render();
    html.window.animationFrame.then(onAnimationFrame);
  }
  html.window.animationFrame.then(onAnimationFrame);

  html.window.onKeyDown.forEach((event) {
    final decodedCode = _decodeKeyCode(event);
    if (decodedCode != null) {
      delegate.onKeyDown(decodedCode);
    }
  });
}

SceneKeyCode? _decodeKeyCode(html.KeyboardEvent event) {
  switch(event.code) {
    case 'KeyW':
      return SceneKeyCode.W;

    case 'KeyA':
      return SceneKeyCode.A;

    case 'KeyS':
      return SceneKeyCode.S;

    case 'KeyD':
      return SceneKeyCode.D;
  }
  return null;
}

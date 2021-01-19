import 'dart:html' as html;
import 'dart:web_gl' as gl;

import 'package:dvwd3d_app/misc/utils.dart';
import 'package:dvwd3d_app/testss/test_scene_01.dart';
import 'package:dvwd3d_app/testss/test_scene_02.dart';
import 'package:dvwd3d_app/ymain.dart';

void main() {
  html.CanvasElement findCanvas(String selectors) {
    final element = html.document.querySelector(selectors);
    return element as html.CanvasElement;
  }
  final canvas = findCanvas('#main-render-canvas');
  //runRenderOnCanvas(canvas, (glContext) => TestScene_01_Delegate(glContext));
  //runRenderOnCanvas(canvas, (glContext) => TestScene_02_Delegate(glContext));
  runRenderOnCanvas(canvas, (glContext) => YMain_SceneDelegate(glContext));
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
    delegate.animate(timestamp);
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
    case 'KeyA':
      return SceneKeyCode.A;

    case 'KeyD':
      return SceneKeyCode.D;

    case 'KeyE':
      return SceneKeyCode.E;

    case 'KeyQ':
      return SceneKeyCode.Q;

    case 'KeyR':
      return SceneKeyCode.R;

    case 'KeyS':
      return SceneKeyCode.S;

    case 'KeyW':
      return SceneKeyCode.W;
  }
  return null;
}

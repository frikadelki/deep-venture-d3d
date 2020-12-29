import 'dart:html' as html;
import 'dart:web_gl' as gl;

import 'package:dvwd3d_app/render_root.dart';
import 'package:dvwd3d_app/test_scene_01.dart';

void main() {
  html.CanvasElement findCanvas(String selectors) {
    final element = html.document.querySelector(selectors);
    return element as html.CanvasElement;
  }
  final canvas = findCanvas('#main-render-canvas');
  runRenderOnCanvas(canvas, (glContext) => TestRender01(glContext));
}

void runRenderOnCanvas(
  html.CanvasElement canvas,
  RenderDelegate Function(gl.RenderingContext) renderFactory) {
  final glContext = canvas.getContext3d();
  final delegate = renderFactory(glContext);

  void resize() {
    delegate.resize(canvas.width ?? 128, canvas.height ?? 128);
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
}

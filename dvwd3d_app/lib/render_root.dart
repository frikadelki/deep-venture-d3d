
enum SceneKeyCode {
  W,
  A,
  S,
  D,
  Q,
  E,
  R,
}

abstract class SceneDelegate {
  void onKeyDown(SceneKeyCode code);

  void animate(num timestamp);

  void render();

  void resize(int width, int height);

  void dispose();
}

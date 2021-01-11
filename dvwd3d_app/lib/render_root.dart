
enum SceneKeyCode {
  W,
  A,
  S,
  D,
  R,
}

abstract class SceneDelegate {
  void onKeyDown(SceneKeyCode code);

  void render();

  void resize(int width, int height);

  void dispose();
}

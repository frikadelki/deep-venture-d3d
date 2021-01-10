
enum SceneKeyCode {
  W,
  A,
  S,
  D,
}

abstract class SceneDelegate {
  void onKeyDown(SceneKeyCode code);

  void render();

  void resize(int width, int height);

  void dispose();
}

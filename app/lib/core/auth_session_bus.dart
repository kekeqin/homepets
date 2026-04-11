import 'dart:async';

class AuthSessionBus {
  final StreamController<void> _controller =
      StreamController<void>.broadcast(sync: true);

  Stream<void> get stream => _controller.stream;

  void notifyUnauthorized() {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

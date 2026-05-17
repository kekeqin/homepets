import 'dart:async';

class SubscriptionAccessEvent {
  const SubscriptionAccessEvent({this.reason, this.trialEndsAt});

  final String? reason;
  final DateTime? trialEndsAt;
}

class SubscriptionAccessBus {
  final StreamController<SubscriptionAccessEvent> _controller =
      StreamController<SubscriptionAccessEvent>.broadcast();

  Stream<SubscriptionAccessEvent> get stream => _controller.stream;

  void notifyEntitlementRequired({String? reason, DateTime? trialEndsAt}) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(
      SubscriptionAccessEvent(reason: reason, trialEndsAt: trialEndsAt),
    );
  }

  void dispose() {
    _controller.close();
  }
}

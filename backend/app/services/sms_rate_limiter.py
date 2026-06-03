from collections import defaultdict, deque
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from math import ceil
from threading import Lock


class SmsRateLimiter:
    def __init__(
        self,
        *,
        send_cooldown_seconds: int,
        phone_send_limit_per_hour: int,
        ip_send_limit_per_hour: int,
        phone_verify_failure_limit: int,
        ip_verify_failure_limit: int,
        verify_failure_window_seconds: int,
        now: Callable[[], datetime] | None = None,
    ) -> None:
        self._send_cooldown = timedelta(seconds=send_cooldown_seconds)
        self._send_window = timedelta(hours=1)
        self._verify_window = timedelta(seconds=verify_failure_window_seconds)
        self._phone_send_limit = phone_send_limit_per_hour
        self._ip_send_limit = ip_send_limit_per_hour
        self._phone_verify_failure_limit = phone_verify_failure_limit
        self._ip_verify_failure_limit = ip_verify_failure_limit
        self._now = now or (lambda: datetime.now(UTC))
        self._phone_sends: defaultdict[str, deque[datetime]] = defaultdict(deque)
        self._ip_sends: defaultdict[str, deque[datetime]] = defaultdict(deque)
        self._phone_verify_failures: defaultdict[str, deque[datetime]] = defaultdict(deque)
        self._ip_verify_failures: defaultdict[str, deque[datetime]] = defaultdict(deque)
        self._lock = Lock()

    def retry_after_send(self, phone: str, ip_address: str) -> int:
        with self._lock:
            now = self._now()
            phone_events = self._phone_sends[phone]
            ip_events = self._ip_sends[ip_address]
            self._prune(phone_events, now - self._send_window)
            self._prune(ip_events, now - self._send_window)

            cooldown_retry = 0
            if phone_events:
                cooldown_retry = self._seconds_until(phone_events[-1] + self._send_cooldown, now)

            return max(
                cooldown_retry,
                self._window_retry_after(
                    phone_events, self._phone_send_limit, self._send_window, now
                ),
                self._window_retry_after(ip_events, self._ip_send_limit, self._send_window, now),
            )

    def record_send(self, phone: str, ip_address: str) -> None:
        with self._lock:
            now = self._now()
            self._phone_sends[phone].append(now)
            self._ip_sends[ip_address].append(now)

    def retry_after_verify(self, phone: str, ip_address: str) -> int:
        with self._lock:
            now = self._now()
            phone_events = self._phone_verify_failures[phone]
            ip_events = self._ip_verify_failures[ip_address]
            self._prune(phone_events, now - self._verify_window)
            self._prune(ip_events, now - self._verify_window)

            return max(
                self._window_retry_after(
                    phone_events,
                    self._phone_verify_failure_limit,
                    self._verify_window,
                    now,
                ),
                self._window_retry_after(
                    ip_events,
                    self._ip_verify_failure_limit,
                    self._verify_window,
                    now,
                ),
            )

    def record_verify_failure(self, phone: str, ip_address: str) -> None:
        with self._lock:
            now = self._now()
            self._phone_verify_failures[phone].append(now)
            self._ip_verify_failures[ip_address].append(now)

    def clear_verify_failures(self, phone: str, ip_address: str) -> None:
        with self._lock:
            self._phone_verify_failures.pop(phone, None)
            self._ip_verify_failures.pop(ip_address, None)

    def reset(self) -> None:
        with self._lock:
            self._phone_sends.clear()
            self._ip_sends.clear()
            self._phone_verify_failures.clear()
            self._ip_verify_failures.clear()

    def _window_retry_after(
        self,
        events: deque[datetime],
        limit: int,
        window: timedelta,
        now: datetime,
    ) -> int:
        if limit <= 0 or len(events) < limit:
            return 0
        return self._seconds_until(events[0] + window, now)

    def _seconds_until(self, target: datetime, now: datetime) -> int:
        return max(0, ceil((target - now).total_seconds()))

    def _prune(self, events: deque[datetime], cutoff: datetime) -> None:
        while events and events[0] <= cutoff:
            events.popleft()

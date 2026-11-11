#!/usr/bin/env python3
"""Bounded child process-group lifecycle helpers for generic credential exec.

Shared guard used by the exec runners (credential_exec, credential_terminal):

- ``ExecInterrupted(signum)``: raised by the INT/TERM handlers installed while
  a child is managed, so runners can map an interrupt to ``128 + signum``.
- ``managed_child(process)``: context manager that installs those handlers,
  yields, then always performs bounded process-group cleanup in ``finally``
  (TERM, short grace, KILL, reap) and restores the handlers. Cleanup runs even
  after a normal leader exit so descendants that inherited pipes cannot
  outlive the run. The child must have been started with
  ``start_new_session=True`` (its PID is then its process-group leader).
- ``child_exited(process)``: leader-exit detection via ``waitid`` with
  ``WNOWAIT``; it never reaps, so the real status stays recoverable for
  ``exit_status`` after cleanup.
- ``exit_status(process)``: shell exit status of the reaped child, or
  ``128 + signum`` when it died from a signal.

Signal handlers may only be installed from the main thread; misuse fails
closed with ``RuntimeError('execute')``. Errors use the shared fixed
taxonomy, never secret material.
"""

import os
import signal
import subprocess
import time
from contextlib import contextmanager

# Grace between group TERM and group KILL, and the bound on waiting for the
# (already dead or reaped) leader before giving up.
TERM_GRACE_SECONDS = 0.2
REAP_TIMEOUT_SECONDS = 1.0


class ExecInterrupted(Exception):
    """SIGINT or SIGTERM reached this process while a child was managed."""

    def __init__(self, signum: int):
        super().__init__(signum)
        self.signum = signum


def child_exited(process: subprocess.Popen) -> bool:
    """True once the leader exited, without reaping it.

    ``WNOWAIT`` leaves the zombie in place so ``managed_child`` can still
    ``wait()`` it afterwards and recover the real exit status.
    """
    try:
        info = os.waitid(os.P_PID, process.pid, os.WEXITED | os.WNOHANG | os.WNOWAIT)
    except ChildProcessError:
        # Already reaped or no longer our child: treat as exited.
        return True
    return info is not None and info.si_pid != 0


def exit_status(process: subprocess.Popen) -> int:
    """Shell exit status after ``managed_child`` returned (reaped child)."""
    code = process.returncode
    if code is None:
        raise RuntimeError("execute") from None
    return code if code >= 0 else 128 - code


def _terminate_group(process: subprocess.Popen) -> None:
    # The child was started in a new session, so its PID is also its process
    # group and session leader. Ignore INT/TERM while cleanup is in progress;
    # they must not interrupt the grace period before SIGKILL reaches
    # descendants that ignored the first TERM.
    previous = {}
    for sig in (signal.SIGINT, signal.SIGTERM):
        previous[sig] = signal.signal(sig, signal.SIG_IGN)
    try:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        time.sleep(TERM_GRACE_SECONDS)
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=REAP_TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            pass
    finally:
        for sig, handler in previous.items():
            signal.signal(sig, handler)


@contextmanager
def managed_child(process: subprocess.Popen):
    """Guard a child started in its own session.

    Installs INT/TERM handlers that raise ``ExecInterrupted(signum)`` in the
    main thread, yields the process, then always performs the bounded group
    cleanup and restores the previous handlers.
    """
    previous = {}

    def interrupt(signum, _frame):
        raise ExecInterrupted(signum)

    try:
        previous[signal.SIGINT] = signal.signal(signal.SIGINT, interrupt)
        previous[signal.SIGTERM] = signal.signal(signal.SIGTERM, interrupt)
    except ValueError:
        # Not the main thread: signal delivery could not be redirected.
        raise RuntimeError("execute") from None
    try:
        yield process
    finally:
        _terminate_group(process)
        for sig, handler in previous.items():
            signal.signal(sig, handler)

#!/usr/bin/env python3
"""Controlled terminal prompt broker for generic credential exec.

Runs a trusted command inside a fresh PTY session with a real controlling
terminal, resolves ordered one-shot literal prompt bindings, and forwards the
command's merged stdout+stderr to this helper's stdout through streaming
literal redaction.

Safety gates:
- The command runs as a fresh interpreter child that acquires the PTY as its
  controlling terminal via TIOCSCTTY (getpass and /dev/tty work), started with
  ``start_new_session`` and ``pass_fds`` only: no ``preexec_fn`` and no
  ``pty.fork`` after GI threads may have started.
- The parent keeps the PTY slave open to query termios state and holds it
  until every prompt step is injected, so PTY EOF cannot arrive early. The
  helper never calls ``tcsetattr``: it verifies local ECHO is off before
  injecting and fails closed otherwise. Local echo off is NOT proof that a
  remote (e.g. SSH) echo is off.
- Prompt matching is byte-exact on the raw output stream against the ordered
  literal bindings only: no guessing, no retries, no regex. Each binding
  injects at most once, and only after its prompt matched and echo was
  verified off.
- Parent stdin is not forwarded to the child before all bindings are
  injected, so parent input cannot precede prompt authentication.
- Every output byte passes through LiteralRedactor before it is written, so
  echoed secrets are removed, including occurrences split across read
  chunks. This is defense-in-depth for trusted commands only: transformed,
  encoded, or reformatted output is not covered.
- Prompt resolution is bounded by an overall deadline; unmatched prompts,
  echo staying on, or a child that exits before prompting fail closed with
  RuntimeError('prompt') and no injection.
- Parent stdin EOF is propagated with VEOF in canonical mode. Raw mode has no
  portable PTY EOF signal: forwarding stops, but output collection and normal
  child exit continue; raw-mode targets that require EOF need client-specific
  handling or cancellation.
- Process-group cleanup is bounded (managed_child); target exit status is
  preserved after the context returns.

Errors use the shared fixed taxonomy only, never secret material:
RuntimeError('prompt') for unsafe/unmatched/timed-out bindings,
RuntimeError('execute') for other internal failures. Values must already be
validated by the caller; here a binding is unsafe if its value is empty or
exceeds the canonical-mode tty line limit.
"""

import fcntl
import os
import selectors
import select
import stat
import subprocess
import sys
import termios
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.insert(0, _HERE)

from credential_redaction import LiteralRedactor
from credential_process import (
    ExecInterrupted,
    child_exited,
    exit_status,
    managed_child,
)

__all__ = ["run_terminal", "PROMPT_TIMEOUT"]

# Overall bound for resolving every prompt binding (matching + echo check +
# injection). Test harnesses may monkeypatch this.
PROMPT_TIMEOUT = 90
# Short race window allowed between a prompt match and the target's own
# echo-disable before failing closed. Never forced, never retried.
ECHO_GRACE = 5.0
# Bounded drain after leader exit before group cleanup (EOF/descendant hang).
DRAIN_TIMEOUT = 5
# Bounded pending buffer for forwarded parent stdin (backpressure).
STDIN_PEND_LIMIT = 256 * 1024
# Canonical-mode tty input lines are limited; a longer injected value would
# be silently truncated by the line discipline, so refuse instead.
MAX_PROMPT_VALUE_BYTES = 4095

# Fresh interpreter child: acquire the controlling TTY, make the PTY slave
# stdin/stdout/stderr, then exec the target. Contains no secret material;
# the target and its arguments arrive as argv.
_TTY_CHILD_CODE = r'''
import fcntl, os, sys, termios
fd = int(sys.argv[1])
fcntl.ioctl(fd, termios.TIOCSCTTY, 0)
os.dup2(fd, 0)
os.dup2(fd, 1)
os.dup2(fd, 2)
if fd > 2:
    os.close(fd)
os.closerange(3, 4096)
try:
    os.execvp(sys.argv[2], sys.argv[2:])
except BaseException:
    os._exit(127)
'''


def _write_output(data: bytes) -> None:
    if data:
        sys.stdout.buffer.write(data)
        sys.stdout.flush()


def _echo_is_on(fd: int) -> bool:
    """Verify local echo state; this side never forces it off."""
    try:
        attrs = termios.tcgetattr(fd)
    except termios.error:
        return True
    return bool(attrs[3] & termios.ECHO)


def _write_all(master_fd: int, data: bytes) -> None:
    offset = 0
    deadline = time.monotonic() + 2.0
    while offset < len(data):
        try:
            written = os.write(master_fd, data[offset:])
            if written <= 0:
                raise RuntimeError("prompt") from None
            offset += written
        except BlockingIOError:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise RuntimeError("prompt") from None
            try:
                _, writable, _ = select.select([], [master_fd], [], remaining)
            except (OSError, ValueError):
                raise RuntimeError("prompt") from None
            if not writable:
                raise RuntimeError("prompt") from None


def _inject(master_fd: int, value: bytes) -> None:
    _write_all(master_fd, value + b"\n")


def _pump_terminal(process, master_fd: int, slave_fd: int,
                   close_slave, steps: list, secrets: list) -> None:
    """Run the child, resolve ordered prompt steps, forward redacted output.

    steps: mutable list of (literal_bytes, value_bytes), consumed in order.
    Raises RuntimeError('prompt') on any fail-closed prompt condition.
    """
    red = LiteralRedactor(secrets)
    deadline = time.monotonic() + PROMPT_TIMEOUT
    selector = selectors.DefaultSelector()
    selector.register(master_fd, selectors.EVENT_READ)
    # Bounded raw suffix held back from the redactor so an upcoming prompt
    # literal that spans chunk boundaries can still be matched. Never grows
    # beyond (next literal length - 1); flushed at EOF.
    match_tail = b""
    awaiting_echo = False
    echo_deadline = None
    stdin_live = False
    stdin_done = False
    stdin_eof_sent = False
    stdin_regular = stat.S_ISREG(os.fstat(0).st_mode)
    stdin_pend = bytearray()
    leader_exited = False
    drain_until = None

    def consume(buf: bytes) -> None:
        nonlocal match_tail, awaiting_echo, echo_deadline
        while True:
            if steps and not awaiting_echo:
                literal = steps[0][0]
                idx = buf.find(literal)
                if idx != -1:
                    region = buf[: idx + len(literal)]
                    # The matched prompt region still goes through the
                    # redactor: a secret value overlapping the prompt text
                    # must not survive either.
                    _write_output(red.feed(region))
                    buf = buf[idx + len(literal):]
                    awaiting_echo = True
                    echo_deadline = min(
                        deadline, time.monotonic() + ECHO_GRACE)
                    continue
            upcoming = None
            if steps:
                upcoming = steps[1][0] if awaiting_echo and len(steps) > 1 \
                    else steps[0][0]
            keep = len(upcoming) - 1 if upcoming else 0
            if len(buf) > keep:
                _write_output(red.feed(buf[: len(buf) - keep]))
                buf = buf[len(buf) - keep:]
            break
        match_tail = buf

    try:
        while True:
            now = time.monotonic()
            if not leader_exited and child_exited(process):
                leader_exited = True
                drain_until = now + DRAIN_TIMEOUT
            if drain_until is not None and now >= drain_until:
                if steps or awaiting_echo:
                    raise RuntimeError("prompt") from None
                break
            if (steps or awaiting_echo) and now >= deadline:
                raise RuntimeError("prompt") from None
            if not steps and not awaiting_echo and stdin_regular and not stdin_done \
                    and len(stdin_pend) < STDIN_PEND_LIMIT:
                try:
                    data = os.read(0, min(4096, STDIN_PEND_LIMIT - len(stdin_pend)))
                except OSError:
                    data = b""
                if data:
                    stdin_pend.extend(data)
                else:
                    stdin_done = True
            if awaiting_echo and now >= echo_deadline and _echo_is_on(slave_fd):
                # Echo stayed on: fail closed, never inject, never force.
                raise RuntimeError("prompt") from None
            timeout = 0.1
            if drain_until is not None:
                timeout = min(timeout, max(0.0, drain_until - time.monotonic()))
            if awaiting_echo:
                timeout = min(timeout, max(0.0, echo_deadline - now))
            eof = False
            for key, _ in selector.select(timeout):
                if key.fd == master_fd:
                    try:
                        chunk = os.read(master_fd, 4096)
                    except BlockingIOError:
                        continue
                    except OSError:
                        chunk = b""
                    if not chunk:
                        eof = True
                        break
                    if (steps or awaiting_echo) and \
                            time.monotonic() >= deadline:
                        raise RuntimeError("prompt") from None
                    consume(match_tail + chunk)
                elif key.fd == 0 and not stdin_done:
                    try:
                        data = os.read(0, 4096)
                    except OSError:
                        data = b""
                    if data:
                        stdin_pend.extend(data)
                        if len(stdin_pend) > STDIN_PEND_LIMIT:
                            selector.unregister(0)
                            stdin_live = False
                    else:
                        stdin_done = True
                        if stdin_live:
                            selector.unregister(0)
                            stdin_live = False
            if awaiting_echo and not _echo_is_on(slave_fd):
                _inject(master_fd, steps[0][1])
                steps.pop(0)
                awaiting_echo = False
                echo_deadline = None
                if not steps:
                    # All bindings injected: release the parent's slave copy
                    # so PTY EOF can surface later, then forward parent stdin.
                    close_slave()
                    if not stdin_done and not stdin_regular:
                        try:
                            selector.register(0, selectors.EVENT_READ)
                            stdin_live = True
                        except (OSError, ValueError):
                            stdin_done = True
            if eof:
                if steps or awaiting_echo:
                    raise RuntimeError("prompt") from None
                # Closing the terminal is not the same as exiting. Keep the
                # cancellation guard active while a detached target finishes.
                while not child_exited(process):
                    time.sleep(0.1)
                break
            if stdin_pend:
                try:
                    sent = os.write(master_fd, stdin_pend)
                    if sent > 0:
                        del stdin_pend[:sent]
                except BlockingIOError:
                    pass
                except OSError:
                    stdin_pend.clear()
                    stdin_done = True
                    if stdin_live:
                        selector.unregister(0)
                        stdin_live = False
            if stdin_done and not stdin_pend and not stdin_eof_sent:
                # Canonical PTYs signal EOF with VEOF. Raw mode has no
                # portable equivalent; stop forwarding without aborting the
                # authenticated command or its output collection.
                try:
                    attrs = termios.tcgetattr(master_fd)
                    if attrs[3] & termios.ICANON:
                        veof = attrs[6][termios.VEOF]
                        if isinstance(veof, int):
                            veof = bytes([veof])
                        if not veof:
                            raise RuntimeError("execute") from None
                        # First VEOF flushes an unterminated canonical line;
                        # the second produces EOF on the following read.
                        _write_all(master_fd, veof)
                        _write_all(master_fd, veof)
                    stdin_eof_sent = True
                except termios.error:
                    raise RuntimeError("execute") from None
            if not stdin_live and not stdin_done and not stdin_regular \
                    and not steps and not awaiting_echo \
                    and len(stdin_pend) < STDIN_PEND_LIMIT:
                try:
                    selector.register(0, selectors.EVENT_READ)
                    stdin_live = True
                except (OSError, ValueError):
                    stdin_done = True
    finally:
        selector.close()
    # Flush the held raw match tail (never forwarded yet), then the
    # redactor's own EOF-pending bytes, each redacted exactly once.
    if match_tail:
        _write_output(red.feed(match_tail))
    _write_output(red.finish())


def run_terminal(command: list, env: dict, prompts: list,
                 secrets: list) -> int:
    """Run command on a controlled PTY with ordered literal prompt bindings.

    command: fully resolved argv of the trusted target (no secret values).
    env: full child environment, including env bindings (child-only).
    prompts: ordered (literal, value) steps; literal is the exact prompt text
        to match, value is the secret to inject once, after ECHO off.
    secrets: every secret byte string that must never appear in forwarded
        output (values for this terminal plus any env-bound values).

    Returns the target's exit status, or 128+signum on INT/TERM. Raises
    RuntimeError('prompt') fail-closed for unsafe/unmatched/timed-out
    bindings and RuntimeError('execute') for other internal failures.
    """
    steps = [(literal.encode("utf-8"), value) for literal, value in prompts]
    for literal, value in steps:
        if not literal or not value or len(value) + 1 > MAX_PROMPT_VALUE_BYTES:
            raise RuntimeError("prompt") from None
    master_fd, slave_fd = os.openpty()
    slave_open = True

    def close_slave():
        nonlocal slave_open
        if slave_open:
            slave_open = False
            os.close(slave_fd)

    try:
        fcntl.fcntl(master_fd, fcntl.F_SETFL, os.O_NONBLOCK)
        process = subprocess.Popen(
            [sys.executable, "-c", _TTY_CHILD_CODE, str(slave_fd), *command],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            env=env,
            start_new_session=True,
            close_fds=True,
            pass_fds=(slave_fd,),
        )
    except BaseException:
        os.close(master_fd)
        close_slave()
        raise
    try:
        try:
            with managed_child(process):
                _pump_terminal(process, master_fd, slave_fd, close_slave,
                               steps, secrets)
        except ExecInterrupted as exc:
            return 128 + exc.signum
        except (ValueError, RuntimeError):
            raise
        except Exception:
            raise RuntimeError("execute") from None
        return exit_status(process)
    finally:
        try:
            os.close(master_fd)
        except OSError:
            pass
        try:
            close_slave()
        except OSError:
            pass

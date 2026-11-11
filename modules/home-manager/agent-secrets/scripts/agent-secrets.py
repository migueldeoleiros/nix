#!/usr/bin/env python3
"""Secret Service enrollment and generic private credential delivery."""

import fcntl
import hashlib
import os
import re
import selectors
import signal
import stat
import subprocess
import sys
import threading
import time
from contextlib import contextmanager
from typing import Optional


APPLICATION = "nix-config-agent-secrets"
SCHEMA_NAME = "org.gnome.keyring.Note"
NAME_RE = re.compile(r"\A[a-z0-9][a-z0-9-]{0,63}\Z", re.ASCII)
MAX_SECRET_BYTES = 64 * 1024
PROMPT_TIMEOUT = 90
LOOKUP_TIMEOUT = 4
ENROLL_TIMEOUT = 5
LOCK_TIMEOUT = 5
ZENITY = os.environ.get("ZENITY", "zenity")

STATUS_ERRORS = {
    "usage": "agent-secrets: invalid command or metadata",
    "unavailable": "agent-secrets: keyring unavailable",
    "locked": "agent-secrets: keyring locked; unlock it in the desktop session",
    "missing": "agent-secrets: credential unavailable",
    "cancelled": "agent-secrets: enrollment cancelled",
    "gui": "agent-secrets: enrollment dialog failed",
    "conflict": "agent-secrets: credential exists or changed; no update made",
    "store": "agent-secrets: enrollment failed",
    "busy": "agent-secrets: another enrollment is active or the lock is unavailable",
    "output": "agent-secrets: private output unavailable",
    "invalid": "agent-secrets: invalid credential value",
    "prompt": "agent-secrets: prompt binding unmatched, unsafe, or timed out",
    "execute": "agent-secrets: command execution failed",
}


class PromptAborted(Exception):
    pass


class OperationTimedOut(Exception):
    pass


def fail(code: str) -> int:
    print(STATUS_ERRORS[code], file=sys.stderr)
    return 1


def valid_name(name: str) -> bool:
    return NAME_RE.fullmatch(name) is not None


def secret_api():
    import gi

    gi.require_version("Secret", "1")
    from gi.repository import Gio, Secret

    # Match Seahorse's Add Password format, without custom attributes.
    schema = Secret.Schema.new(SCHEMA_NAME, Secret.SchemaFlags.NONE, {})
    return Gio, Secret, schema


def named_items(service, Secret, schema, name: str, cancellable):
    # Labels are metadata, not secrets. Never unlock or load unrelated values.
    items = service.search_sync(schema, {}, Secret.SearchFlags.ALL, cancellable)
    return [item for item in items if item.get_label() == name]


def _check_private_directory(fd: int) -> None:
    info = os.fstat(fd)
    if (
        not stat.S_ISDIR(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_mode & 0o077
        or info.st_mode & 0o300 != 0o300
    ):
        raise OSError("unsafe runtime directory")


@contextmanager
def enrollment_lock(name: str):
    """Serialize this helper's enrollment for one exact credential name."""
    runtime = os.environ.get("XDG_RUNTIME_DIR", "")
    if not runtime or not os.path.isabs(runtime) or os.path.normpath(runtime) != runtime:
        raise OSError("private runtime directory unavailable")
    runtime_fd = os.open(runtime, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    lock_dir_fd = lock_fd = None
    try:
        _check_private_directory(runtime_fd)
        try:
            os.mkdir("agent-secrets", 0o700, dir_fd=runtime_fd)
        except FileExistsError:
            pass
        lock_dir_fd = os.open(
            "agent-secrets",
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC,
            dir_fd=runtime_fd,
        )
        _check_private_directory(lock_dir_fd)
        identity = "\0".join((APPLICATION, name)).encode("ascii")
        lock_name = hashlib.sha256(identity).hexdigest() + ".lock"
        lock_fd = os.open(
            lock_name,
            os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW | os.O_CLOEXEC,
            0o600,
            dir_fd=lock_dir_fd,
        )
        lock_info = os.fstat(lock_fd)
        if (
            not stat.S_ISREG(lock_info.st_mode)
            or lock_info.st_uid != os.getuid()
            or lock_info.st_nlink != 1
            or lock_info.st_mode & 0o077
            or lock_info.st_mode & 0o600 != 0o600
        ):
            raise OSError("unsafe lock file")
        deadline = time.monotonic() + LOCK_TIMEOUT
        while True:
            try:
                fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise TimeoutError("enrollment lock timed out") from None
                time.sleep(min(0.05, max(0, deadline - time.monotonic())))
        yield
    finally:
        if lock_fd is not None:
            os.close(lock_fd)
        if lock_dir_fd is not None:
            os.close(lock_dir_fd)
        os.close(runtime_fd)


def cancellable_call(Gio, timeout: int, callback):
    cancellable = Gio.Cancellable.new()
    timer = threading.Timer(timeout, cancellable.cancel)
    timer.daemon = True
    timer.start()
    try:
        result = callback(cancellable)
        if cancellable.is_cancelled():
            raise OperationTimedOut()
        return result
    finally:
        timer.cancel()


def get_unlocked_value(name: str) -> Optional[str]:
    """Search without UNLOCK flags; never request unlock or prompt."""
    try:
        Gio, Secret, schema = secret_api()

        def lookup(cancellable):
            service = Secret.Service.get_sync(Secret.ServiceFlags.NONE, cancellable)
            items = named_items(service, Secret, schema, name, cancellable)
            if not items:
                raise LookupError("missing")
            if len(items) != 1:
                raise LookupError("ambiguous")
            item = items[0]
            if item.get_locked():
                raise PermissionError("locked")
            item.load_secret_sync(cancellable)
            value = item.get_secret().get_text()
            if not value:
                raise LookupError("missing")
            return value

        return cancellable_call(Gio, LOOKUP_TIMEOUT, lookup)
    except (PermissionError, LookupError):
        raise
    except Exception as exc:
        if "locked" in str(exc).lower():
            raise PermissionError("locked") from None
        raise RuntimeError("unavailable") from None


def _prompt_environment() -> dict[str, str]:
    """Pass only desktop access and locale variables to the GUI subprocess."""
    allowed = {
        "HOME", "PATH", "LANG", "LANGUAGE", "DISPLAY", "WAYLAND_DISPLAY",
        "XAUTHORITY", "DBUS_SESSION_BUS_ADDRESS", "XDG_RUNTIME_DIR",
        "XDG_SESSION_TYPE", "XDG_CURRENT_DESKTOP", "GDK_BACKEND",
        "GTK_USE_PORTAL", "GIO_USE_PORTALS",
    }
    env = {key: value for key, value in os.environ.items() if key in allowed or key.startswith("LC_")}
    env["PATH"] = os.environ.get("PATH", "/run/current-system/sw/bin:/usr/bin:/bin")
    return env


def _leader_exited_unreaped(process: subprocess.Popen) -> bool:
    result = os.waitid(os.P_PID, process.pid, os.WEXITED | os.WNOHANG | os.WNOWAIT)
    return result is not None and result.si_pid != 0


def _terminate_group(process: subprocess.Popen) -> None:
    # The child was started in a new session, so its PID is also its process group.
    # Ignore repeated TERM while cleanup is in progress; it must not interrupt the
    # grace period before SIGKILL reaches descendants that ignored the first TERM.
    previous_term = signal.getsignal(signal.SIGTERM)
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    try:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        time.sleep(0.2)
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            pass
    finally:
        signal.signal(signal.SIGTERM, previous_term)


def _run_prompt(args: tuple[str, ...], timeout: int = PROMPT_TIMEOUT) -> subprocess.CompletedProcess:
    """Run GUI in a killable process group, with bounded captured stdout."""
    process = subprocess.Popen(
        [ZENITY, *args],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        env=_prompt_environment(),
        start_new_session=True,
        close_fds=True,
    )
    assert process.stdout is not None
    output = bytearray()
    deadline = time.monotonic() + timeout
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    previous_term = signal.getsignal(signal.SIGTERM)

    def abort(_signum, _frame):
        raise PromptAborted()

    signal.signal(signal.SIGTERM, abort)
    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise subprocess.TimeoutExpired(process.args, timeout)
            events = selector.select(min(remaining, 0.1))
            for key, _ in events:
                chunk = os.read(key.fd, min(4096, MAX_SECRET_BYTES + 2 - len(output)))
                if not chunk:
                    selector.unregister(key.fileobj)
                    continue
                output.extend(chunk)
                if len(output) > MAX_SECRET_BYTES + 1:
                    raise ValueError("prompt output too large")
            if _leader_exited_unreaped(process) and not selector.get_map():
                break
        _terminate_group(process)
        return subprocess.CompletedProcess(process.args, process.returncode, bytes(output), b"")
    except BaseException:
        _terminate_group(process)
        raise
    finally:
        signal.signal(signal.SIGTERM, previous_term)
        selector.close()
        process.stdout.close()


def _prompt(args: tuple[str, ...], timeout: int = PROMPT_TIMEOUT):
    return _run_prompt(args, timeout)


def read_hidden_secret(name: str) -> Optional[str]:
    purpose = f"Store {name} in the system keyring."
    try:
        result = _prompt((
            "--entry",
            "--hide-text",
            "--title=Credential enrollment",
            f"--text={purpose}",
        ))
    except (OSError, subprocess.TimeoutExpired, ValueError, PromptAborted, KeyboardInterrupt):
        raise RuntimeError("gui") from None
    if result.returncode == 1 and not result.stdout:
        return None
    if result.returncode != 0:
        raise RuntimeError("gui")
    raw = result.stdout
    if raw.endswith(b"\n"):
        raw = raw[:-1]
    if not raw or len(raw) > MAX_SECRET_BYTES or b"\0" in raw:
        raise RuntimeError("gui")
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        raise RuntimeError("gui") from None


def confirm_replacement(name: str) -> bool:
    try:
        result = _prompt((
            "--question",
            "--title=Replace credential?",
            f"--text=Replace {name} in the system keyring?",
            "--ok-label=Replace",
            "--cancel-label=Keep existing",
        ))
    except (OSError, subprocess.TimeoutExpired, ValueError, PromptAborted, KeyboardInterrupt):
        raise RuntimeError("gui") from None
    if result.returncode == 0 and not result.stdout:
        return True
    if result.returncode == 1 and not result.stdout:
        return False
    raise RuntimeError("gui")


def _enroll_locked(name: str) -> int:
    try:
        Gio, Secret, schema = secret_api()

        def connect_and_search(cancellable):
            service = Secret.Service.get_sync(Secret.ServiceFlags.NONE, cancellable)
            items = named_items(service, Secret, schema, name, cancellable)
            return service, items

        service, initial = cancellable_call(Gio, ENROLL_TIMEOUT, connect_and_search)
        if len(initial) > 1:
            return fail("conflict")
        existing = initial[0] if initial else None
        if existing is not None and existing.get_locked():
            return fail("locked")
        if existing is not None and not confirm_replacement(name):
            return fail("conflict")
        secret_text = read_hidden_secret(name)
        if secret_text is None:
            return fail("cancelled")

        def store(cancellable):
            current = named_items(service, Secret, schema, name, cancellable)
            if len(current) > 1:
                raise LookupError("ambiguous")
            if existing is None:
                if current:
                    raise LookupError("changed")
            elif not current or current[0].get_object_path() != existing.get_object_path():
                raise LookupError("changed")
            secret_value = Secret.Value.new(secret_text, -1, "text/plain")
            if existing is None:
                collection = Secret.Collection.for_alias_sync(
                    service, Secret.COLLECTION_DEFAULT, Secret.CollectionFlags.NONE, cancellable
                )
                if collection is None:
                    raise RuntimeError("default keyring unavailable")
                if collection.get_locked():
                    raise PermissionError("locked")
                # Generic notes share empty attributes. Never use store_sync's
                # attribute-based replacement: it could overwrite another note.
                return Secret.Item.create_sync(
                    collection, schema, {}, name, secret_value,
                    Secret.ItemCreateFlags.NONE, cancellable,
                ) is not None
            if current[0].get_locked():
                raise PermissionError("locked")
            return current[0].set_secret_sync(secret_value, cancellable)

        if not cancellable_call(Gio, ENROLL_TIMEOUT, store):
            return fail("store")
        print("agent-secrets: credential stored")
        return 0
    except PermissionError:
        return fail("locked")
    except LookupError:
        return fail("conflict")
    except Exception:
        return fail("store")
    finally:
        if "secret_text" in locals():
            secret_text = None


def enroll(name: str) -> int:
    if not valid_name(name):
        return fail("usage")
    try:
        # Hold this lock from before the first lookup through prompting and storage.
        with enrollment_lock(name):
            return _enroll_locked(name)
    except TimeoutError:
        return fail("busy")
    except OSError:
        return fail("busy")


def load_value(name: str, trim_eol: bool = False) -> str:
    """Load one explicit name; formatting is a caller choice, never identity-based."""
    if not valid_name(name):
        raise ValueError("usage")
    try:
        value = get_unlocked_value(name)
    except PermissionError:
        raise RuntimeError("locked") from None
    except LookupError:
        raise RuntimeError("missing") from None
    except RuntimeError:
        raise RuntimeError("unavailable") from None
    if not isinstance(value, str):
        raise ValueError("invalid")
    if trim_eol:
        value = value.rstrip("\r\n")
    if not value or any(ord(char) < 32 or ord(char) == 127 for char in value):
        raise ValueError("invalid")
    try:
        if len(value.encode("utf-8")) > MAX_SECRET_BYTES:
            raise ValueError("invalid")
    except UnicodeError:
        raise ValueError("invalid") from None
    return value


def read_private(name: str, trim_eol: bool = False) -> int:
    if sys.stdout.isatty():
        return fail("output")
    value = load_value(name, trim_eol)
    try:
        # Application-owned pipes only; agent tools must use exec instead.
        sys.stdout.buffer.write(value.encode("utf-8"))
        sys.stdout.buffer.flush()
        return 0
    except (BrokenPipeError, OSError):
        return fail("output")
    finally:
        value = None


def main(argv: list[str]) -> int:
    try:
        if len(argv) == 3 and argv[1] == "enroll":
            return enroll(argv[2])
        if len(argv) == 3 and argv[1] == "read":
            return read_private(argv[2])
        if len(argv) == 4 and argv[1:3] == ["read", "--trim-eol"]:
            return read_private(argv[3], True)
        if len(argv) >= 3 and argv[1] == "exec":
            from credential_exec import run_exec

            return run_exec(argv[2:], load_value)
        return fail("usage")
    except KeyboardInterrupt:
        return 130
    except (ValueError, RuntimeError) as error:
        code = str(error)
        return fail(code if code in STATUS_ERRORS else "execute")
    except Exception:
        # Exceptions from a target or transport must never expose input values.
        return fail("execute")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

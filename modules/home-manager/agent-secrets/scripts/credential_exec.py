#!/usr/bin/env python3
"""Child-only generic credential environment and terminal prompt broker."""

import os
import selectors
import subprocess
import sys
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.insert(0, _HERE)

from credential_process import (
    ExecInterrupted,
    child_exited,
    exit_status,
    managed_child,
)
from credential_redaction import LiteralRedactor

__all__ = ["run_exec"]

_DRAIN_TIMEOUT = 0.75
_MAX_VALUE_BYTES = 64 * 1024
_MAX_PROMPT_VALUE_BYTES = 4094
_MAX_PROMPT_BYTES = 4096


def _invalid():
    raise ValueError("invalid") from None


def _valid_name(name):
    return (isinstance(name, str) and 1 <= len(name) <= 64
            and name[0] in "abcdefghijklmnopqrstuvwxyz0123456789"
            and all(ch in "abcdefghijklmnopqrstuvwxyz0123456789-" for ch in name))


def _valid_var(var):
    if not var or not (var[0].isascii() and (var[0].isalpha() or var[0] == "_")):
        return False
    return all(ch.isascii() and (ch.isalnum() or ch == "_") for ch in var[1:])


def _parse(argv):
    if not isinstance(argv, list):
        raise ValueError("usage") from None
    env_items, line_items, prompt_items = [], [], []
    used_vars = set()
    i = 0
    while i < len(argv) and argv[i] != "--":
        option = argv[i]
        if option in ("--env", "--env-line"):
            i += 1
            if i >= len(argv) or "=" not in argv[i]:
                raise ValueError("usage") from None
            var, name = argv[i].split("=", 1)
            if not _valid_var(var) or not _valid_name(name):
                _invalid()
            if var in used_vars:
                _invalid()
            used_vars.add(var)
            (env_items if option == "--env" else line_items).append((var, name))
        elif option == "--prompt":
            if i + 2 >= len(argv):
                raise ValueError("usage") from None
            name, literal = argv[i + 1], argv[i + 2]
            if not _valid_name(name):
                _invalid()
            if not isinstance(literal, str) or not literal:
                _invalid()
            try:
                literal_size = len(literal.encode("utf-8"))
            except UnicodeError:
                _invalid()
            if literal_size > _MAX_PROMPT_BYTES:
                _invalid()
            prompt_items.append((name, literal))
            i += 2
        else:
            raise ValueError("usage") from None
        i += 1
    if i >= len(argv) or argv[i] != "--" or i + 1 >= len(argv):
        raise ValueError("usage") from None
    command = argv[i + 1:]
    if any(not isinstance(arg, str) for arg in command):
        raise ValueError("usage") from None
    return env_items, line_items, prompt_items, command


def _resolve(env_items, line_items, prompt_items, load):
    mappings = []
    prompts = []
    secrets = []
    try:
        for var, name in env_items:
            value = load(name, trim_eol=False)
            mappings.append((var, value))
        for var, name in line_items:
            value = load(name, trim_eol=True)
            mappings.append((var, value))
        for name, literal in prompt_items:
            prompts.append((literal, load(name, trim_eol=False)))
    except (ValueError, RuntimeError):
        raise
    except Exception:
        raise RuntimeError("execute") from None

    for _var, value in mappings:
        if not isinstance(value, str) or not value:
            _invalid()
        try:
            encoded = value.encode("utf-8")
        except UnicodeError:
            _invalid()
        if len(encoded) > _MAX_VALUE_BYTES:
            _invalid()
        secrets.append(encoded)
    resolved_prompts = []
    for literal, value in prompts:
        if not isinstance(value, str) or not value:
            _invalid()
        try:
            encoded = value.encode("utf-8")
        except UnicodeError:
            _invalid()
        if len(encoded) > _MAX_VALUE_BYTES:
            _invalid()
        if len(encoded) > _MAX_PROMPT_VALUE_BYTES:
            raise RuntimeError("prompt") from None
        secrets.append(encoded)
        resolved_prompts.append((literal, encoded))
    return mappings, resolved_prompts, secrets


def _write(data, stream):
    if data:
        stream.write(data)
        stream.flush()


def _run_piped(command, env, secrets):
    redactors = {"stdout": LiteralRedactor(secrets),
                 "stderr": LiteralRedactor(secrets)}
    process = None
    selector = selectors.DefaultSelector()
    try:
        process = subprocess.Popen(
            command,
            stdin=None,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            start_new_session=True,
            bufsize=0,
        )
        with managed_child(process):
            for name, pipe in (("stdout", process.stdout), ("stderr", process.stderr)):
                os.set_blocking(pipe.fileno(), False)
                selector.register(pipe, selectors.EVENT_READ, name)
            leader_exited = False
            drain_until = None
            while selector.get_map() or not leader_exited:
                now = time.monotonic()
                if not leader_exited and child_exited(process):
                    leader_exited = True
                    drain_until = now + _DRAIN_TIMEOUT
                if drain_until is not None and now >= drain_until:
                    break
                timeout = 0.1 if drain_until is None else min(0.1, max(0, drain_until - now))
                for key, _ in selector.select(timeout):
                    pipe, name = key.fileobj, key.data
                    try:
                        data = os.read(pipe.fileno(), 65536)
                    except BlockingIOError:
                        continue
                    if data:
                        stream = sys.stdout.buffer if name == "stdout" else sys.stderr.buffer
                        _write(redactors[name].feed(data), stream)
                    else:
                        selector.unregister(pipe)
                        pipe.close()
                        stream = sys.stdout.buffer if name == "stdout" else sys.stderr.buffer
                        _write(redactors[name].finish(), stream)
            # Flush EOF-pending redactor bytes even when the bounded drain ended
            # before descendants closed inherited pipe descriptors.
            for name, redactor in redactors.items():
                stream = sys.stdout.buffer if name == "stdout" else sys.stderr.buffer
                _write(redactor.finish(), stream)
        return exit_status(process)
    except ExecInterrupted:
        raise
    except (ValueError, RuntimeError):
        raise
    except Exception:
        raise RuntimeError("execute") from None
    finally:
        selector.close()
        if process is not None:
            for pipe in (process.stdout, process.stderr):
                if pipe is not None:
                    try:
                        pipe.close()
                    except OSError:
                        pass


def run_exec(argv: list[str], load) -> int:
    """Run argv after ``exec``; load(name, trim_eol) resolves one secret."""
    env_items, line_items, prompt_items, command = _parse(argv)
    mappings, prompts, secrets = _resolve(env_items, line_items, prompt_items, load)
    child_env = os.environ.copy()
    child_env.update(mappings)
    try:
        if prompts:
            from credential_terminal import run_terminal
            return run_terminal(command, child_env, prompts, secrets)
        return _run_piped(command, child_env, secrets)
    except ExecInterrupted as exc:
        return 128 + exc.signum

#!/usr/bin/env python3
"""Streaming literal redaction: longest-literal removal over the original stream.

Semantics: one-pass left-to-right longest-match removal over the original byte
stream. Occurrences created by prior removals are not re-matched. Secret
matches spanning feed() chunk boundaries and EOF-pending bytes are handled.

Internal malformed usage raises ValueError('usage'), invalid values raise
ValueError('invalid'). Never prints secret material.
"""

__all__ = ["LiteralRedactor"]


def _forward_step(buf: bytes, secrets, hold: int):
    """Emit final bytes; keep trailing `hold` bytes (and partial-secret bytes)
    pending. Returns (emit, keep)."""
    if secrets:
        maxlen = max(len(s) for s in secrets)
        keep = max(hold, maxlen - 1)
        out = bytearray(); i = 0; n = len(buf); stop = n - keep
        while i < stop:
            for s in secrets:
                if buf.startswith(s, i):
                    i += len(s); break
            else:
                out.append(buf[i]); i += 1
        emit, rest = bytes(out), bytes(buf[i:])
        # restore hold if a match consumed past the boundary
        if len(rest) < hold:
            cut = hold - len(rest)
            rest = emit[len(emit) - cut:] + rest
            emit = emit[:len(emit) - cut]
        return emit, rest
    if hold:
        return buf[:-hold], buf[len(buf) - hold:]
    return buf, b""


def _redact_final(buf: bytes, secrets) -> bytes:
    """EOF flush: redact the pending tail exactly once."""
    out = bytearray(); i = 0
    while i < len(buf):
        for s in secrets:
            if buf.startswith(s, i):
                i += len(s); break
        else:
            out.append(buf[i]); i += 1
    return bytes(out)


class LiteralRedactor:
    """Streaming longest-literal removal over the original stream.

    LiteralRedactor(secrets: iterable[bytes])
        feed(data: bytes) -> bytes   emit redacted bytes for this chunk
        finish() -> bytes            flush pending tail, redacted once
    """

    def __init__(self, secrets):
        try:
            items = list(secrets)
        except TypeError:
            raise ValueError('usage')
        for s in items:
            if not isinstance(s, bytes):
                raise ValueError('invalid')
            if not s:
                raise ValueError('invalid')
        # longest first; duplicates cannot change matching semantics
        self._secrets = sorted(set(items), key=len, reverse=True)
        self._pending = b""

    def feed(self, data):
        if not isinstance(data, (bytes, bytearray, memoryview)):
            raise ValueError('invalid')
        buf = bytes(self._pending) + bytes(data)
        emit, self._pending = _forward_step(buf, self._secrets, 0)
        return emit

    def finish(self):
        rest, self._pending = bytes(self._pending), b""
        return _redact_final(rest, self._secrets)

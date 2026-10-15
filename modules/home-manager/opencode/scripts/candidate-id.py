#!/usr/bin/env python3
"""Compute a deterministic, read-only identity receipt for a git candidate.

The helper never mutates the index or object store. It hashes:
- scope (worktree or PR)
- resolved HEAD, base, and merge-base commits
- staged changes (`git diff --cached <head>`) and worktree changes
  (`git diff <head>`) using `--no-ext-diff --no-textconv --binary --no-color`
- untracked file contents, modes, and symlink targets

The absolute repository root is recorded in the receipt for diagnostics but is
excluded from the hash, so identical content in different checkouts produces
the same candidate.

Limitations:
- Ignored files are excluded.
- Submodules: only the recorded submodule state from `git diff` is included;
  nested submodule worktree content is not recursively hashed.
- Untracked nested git repositories are not supported and raise an error.
"""

import argparse
import hashlib
import json
import os
import stat
import subprocess
import sys
from typing import Dict, List, Optional


class CandidateError(RuntimeError):
    pass


def _git_env() -> Dict[str, str]:
    env = os.environ.copy()
    env["GIT_OPTIONAL_LOCKS"] = "0"
    env["GIT_CONFIG_GLOBAL"] = "/dev/null"
    env["GIT_CONFIG_SYSTEM"] = "/dev/null"
    return env


def _run(cmd: List[str], cwd: Optional[str] = None) -> bytes:
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=_git_env(),
        )
    except subprocess.CalledProcessError as e:
        msg = e.stderr.decode("utf-8", "replace").strip() if e.stderr else ""
        raise CandidateError(msg or f"command failed: {' '.join(cmd)}") from e
    return result.stdout


def _repo_root(cwd: Optional[str] = None) -> str:
    try:
        out = _run(["git", "rev-parse", "--show-toplevel"], cwd=cwd)
    except CandidateError as e:
        raise CandidateError("not a git repository") from e
    return os.path.abspath(os.fsdecode(out).strip())


def _resolve_commit(ref: str, repo: str) -> str:
    try:
        out = _run(
            ["git", "rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}"],
            cwd=repo,
        )
    except CandidateError as e:
        raise CandidateError(f"invalid ref: {ref}") from e
    return os.fsdecode(out).strip()


def _branch(repo: str) -> Optional[str]:
    try:
        out = subprocess.run(
            ["git", "branch", "--show-current"],
            cwd=repo,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=_git_env(),
        ).stdout
    except subprocess.CalledProcessError:
        return None
    value = os.fsdecode(out).strip()
    return value or None


def _merge_base(base: str, head: str, repo: str) -> str:
    try:
        out = _run(["git", "merge-base", base, head], cwd=repo)
    except CandidateError as e:
        raise CandidateError(f"cannot compute merge-base for {base}..{head}") from e
    return os.fsdecode(out).strip()


def _tracked_diff(repo: str, head: str, base: Optional[str] = None) -> bytes:
    args = [f"{base}...{head}"] if base else [head]
    return _run(
        [
            "git",
            "diff",
            "--no-ext-diff",
            "--no-textconv",
            "--binary",
            "--no-color",
            "--ignore-submodules=none",
            *args,
        ],
        cwd=repo,
    )


def _staged_diff(repo: str, head: str) -> bytes:
    return _run(
        [
            "git",
            "diff",
            "--cached",
            "--no-ext-diff",
            "--no-textconv",
            "--binary",
            "--no-color",
            "--ignore-submodules=none",
            head,
        ],
        cwd=repo,
    )


def _untracked_paths(repo: str) -> List[str]:
    out = _run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        cwd=repo,
    )
    if not out:
        return []
    return [os.fsdecode(p) for p in out.split(b"\0") if p]


def _worktree_dirty(repo: str) -> bool:
    out = _run(
        ["git", "status", "--porcelain", "--ignore-submodules=none"],
        cwd=repo,
    )
    return bool(out.strip())


def _hash_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def _untracked_entry(repo: str, path: str) -> Dict[str, str]:
    full = os.path.join(repo, path)
    try:
        st = os.lstat(full)
    except OSError as e:
        raise CandidateError(f"cannot stat untracked {path}: {e}") from e

    mode = oct(st.st_mode)
    if stat.S_ISLNK(st.st_mode):
        try:
            target = os.readlink(full)
        except OSError as e:
            raise CandidateError(f"cannot read symlink {path}: {e}") from e
        return {"path": path, "kind": "symlink", "mode": mode, "target": target}

    if stat.S_ISREG(st.st_mode):
        try:
            sha = _hash_file(full)
        except OSError as e:
            raise CandidateError(f"cannot read untracked {path}: {e}") from e
        return {"path": path, "kind": "file", "mode": mode, "sha256": sha}

    if stat.S_ISDIR(st.st_mode):
        raise CandidateError(f"untracked directory not supported: {path}")

    raise CandidateError(f"untracked special file not supported: {path}")


def _untracked_manifest(repo: str) -> List[Dict[str, str]]:
    entries = [_untracked_entry(repo, p) for p in _untracked_paths(repo)]
    entries.sort(key=lambda e: e["path"])
    return entries


def _manifest(
    scope: str,
    branch: Optional[str],
    head: str,
    base: str,
    merge_base: str,
    worktree_diff: bytes,
    staged_diff: bytes,
    untracked: List[Dict[str, str]],
    dirty: bool,
) -> bytes:
    obj: Dict = {
        "scope": scope,
        "head": head,
        "base": base,
        "merge_base": merge_base,
        "worktree_diff_sha256": hashlib.sha256(worktree_diff).hexdigest(),
        "staged_diff_sha256": hashlib.sha256(staged_diff).hexdigest(),
        "untracked": untracked,
    }
    if scope == "worktree":
        obj["branch"] = branch
        obj["dirty"] = dirty
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")


def _compute_once(
    repo: str,
    scope: str,
    branch: Optional[str],
    base: Optional[str],
    head: str,
) -> Dict:
    merge_base = head if base is None else _merge_base(base, head, repo)
    worktree_diff = _tracked_diff(repo, head, base)
    staged_diff = _staged_diff(repo, head) if scope == "worktree" else b""
    dirty = _worktree_dirty(repo)
    untracked = _untracked_manifest(repo) if scope == "worktree" else []
    manifest = _manifest(
        scope,
        branch,
        head,
        base or head,
        merge_base,
        worktree_diff,
        staged_diff,
        untracked,
        dirty,
    )
    excluded = ["root"]
    if scope == "pr":
        excluded.extend(["branch", "dirty"])
    return {
        "branch": branch,
        "head": head,
        "base": base or head,
        "merge_base": merge_base,
        "candidate": f"sha256:{hashlib.sha256(manifest).hexdigest()}",
        "dirty": dirty,
        "root": repo,
        "scope": scope,
        "excluded_from_hash": excluded,
    }


def compute_candidate(
    cwd: Optional[str] = None,
    base_ref: Optional[str] = None,
    head_ref: Optional[str] = None,
) -> Dict:
    repo = _repo_root(cwd)

    if bool(base_ref) != bool(head_ref):
        raise CandidateError("--base and --head must be provided together")

    scope = "pr" if base_ref else "worktree"

    if head_ref is None:
        try:
            head = _resolve_commit("HEAD", repo)
        except CandidateError as e:
            raise CandidateError("HEAD missing or unborn") from e
    else:
        head = _resolve_commit(head_ref, repo)

    base = _resolve_commit(base_ref, repo) if base_ref else None
    branch = _branch(repo)

    before = _compute_once(repo, scope, branch, base, head)
    after = _compute_once(repo, scope, branch, base, head)

    if before["candidate"] != after["candidate"]:
        raise CandidateError("candidate changed during capture")

    return after


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Compute deterministic git candidate identity receipt"
    )
    parser.add_argument("--base", help="base ref for PR scope")
    parser.add_argument("--head", help="head ref for PR scope")
    parser.add_argument("--workdir", help="working directory (must be inside a git repo)")
    args = parser.parse_args(argv)

    try:
        receipt = compute_candidate(
            cwd=args.workdir or os.getcwd(),
            base_ref=args.base,
            head_ref=args.head,
        )
    except CandidateError as e:
        sys.stderr.write(f"opencode-candidate-id: {e}\n")
        return 1

    print(json.dumps(receipt, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Unit tests for opencode-candidate-id.

Creates temporary git repositories under /tmp/opencode and verifies that the
helper computes deterministic receipts without mutating the real index.
"""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True

HELPER = Path(__file__).with_name("candidate-id.py").resolve()
TMP_ROOT = Path("/tmp/opencode")

# Import the helper as a module so we can monkeypatch internals.
spec = importlib.util.spec_from_file_location("candidate_id", str(HELPER))
candidate_id = importlib.util.module_from_spec(spec)
spec.loader.exec_module(candidate_id)


class CandidateIdTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        TMP_ROOT.mkdir(parents=True, exist_ok=True)

    def setUp(self):
        self.repo = Path(tempfile.mkdtemp(prefix="test-candidate-id-", dir=TMP_ROOT))
        self._git("init", "-b", "main")
        self._git("config", "user.email", "test@example.com")
        self._git("config", "user.name", "Test User")
        self._git("config", "commit.gpgsign", "false")

    def tearDown(self):
        shutil.rmtree(self.repo, ignore_errors=True)

    def _git(self, *args):
        env = os.environ.copy()
        env["GIT_CONFIG_GLOBAL"] = "/dev/null"
        env["GIT_CONFIG_SYSTEM"] = "/dev/null"
        env["GIT_OPTIONAL_LOCKS"] = "0"
        subprocess.run(
            ["git", *args],
            cwd=self.repo,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            env=env,
        )

    def _run(self, *extra_args, cwd=None, check=True):
        cmd = [sys.executable, str(HELPER), *extra_args]
        env = os.environ.copy()
        env["GIT_CONFIG_GLOBAL"] = "/dev/null"
        env["GIT_CONFIG_SYSTEM"] = "/dev/null"
        env["GIT_OPTIONAL_LOCKS"] = "0"
        result = subprocess.run(
            cmd,
            cwd=cwd or self.repo,
            capture_output=True,
            text=True,
            env=env,
        )
        if check and result.returncode != 0:
            self.fail(f"helper failed: {result.stderr}")
        return result

    def _write(self, path: str, content: bytes):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)

    def _head(self) -> str:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=self.repo, text=True
        ).strip()

    def test_clean_worktree(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        result = self._run()
        data = json.loads(result.stdout)
        self.assertFalse(data["dirty"])
        self.assertEqual(data["branch"], "main")
        self.assertEqual(data["scope"], "worktree")
        self.assertIn("root", data["excluded_from_hash"])
        self.assertTrue(data["candidate"].startswith("sha256:"))
        self.assertTrue(data["candidate"].startswith("sha256:"))

    def test_untracked_content_changes_hash(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        r1 = self._run()
        self._write("untracked.bin", b"\x00\x01\x02")
        r2 = self._run()

        self.assertNotEqual(r1.stdout, r2.stdout)
        c1 = json.loads(r1.stdout)["candidate"]
        c2 = json.loads(r2.stdout)["candidate"]
        self.assertNotEqual(c1, c2)

    def test_nested_untracked_dir_file_edit(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        self._write("nested/dir/file.txt", b"first")
        r1 = self._run()
        self._write("nested/dir/file.txt", b"second")
        r2 = self._run()

        c1 = json.loads(r1.stdout)["candidate"]
        c2 = json.loads(r2.stdout)["candidate"]
        self.assertNotEqual(c1, c2)

    def test_ignored_excluded(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")
        self._write(".gitignore", b"ignored\n")
        self._git("add", ".gitignore")
        self._git("commit", "-m", "ignore")

        r1 = self._run()
        self._write("ignored", b"secret")
        r2 = self._run()

        c1 = json.loads(r1.stdout)["candidate"]
        c2 = json.loads(r2.stdout)["candidate"]
        self.assertEqual(c1, c2)

    def test_staged_and_worktree_changes(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        r1 = self._run()
        self._write("a.txt", b"world")
        self._git("add", "a.txt")
        self._write("a.txt", b"worktree")
        r2 = self._run()

        self.assertNotEqual(r1.stdout, r2.stdout)
        self.assertTrue(json.loads(r2.stdout)["dirty"])

    def test_staged_reversed_file(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        r1 = self._run()
        self._write("a.txt", b"staged")
        self._git("add", "a.txt")
        self._write("a.txt", b"hello")  # revert filesystem to HEAD content
        r2 = self._run()

        c1 = json.loads(r1.stdout)["candidate"]
        c2 = json.loads(r2.stdout)["candidate"]
        self.assertNotEqual(c1, c2)
        self.assertTrue(json.loads(r2.stdout)["dirty"])

    def test_rename_and_delete(self):
        self._write("old.txt", b"content")
        self._git("add", "old.txt")
        self._git("commit", "-m", "init")

        r1 = self._run()
        (self.repo / "old.txt").rename(self.repo / "new.txt")
        self._git("rm", "old.txt")
        self._git("add", "new.txt")
        r2 = self._run()

        self.assertNotEqual(r1.stdout, r2.stdout)

    def test_chmod_tracked_file(self):
        self._write("exec.sh", b"#!/bin/sh\necho hi")
        self._git("add", "exec.sh")
        self._git("commit", "-m", "init")

        r1 = self._run()
        (self.repo / "exec.sh").chmod(0o755)
        r2 = self._run()

        self.assertNotEqual(r1.stdout, r2.stdout)

    def test_symlink_target_included(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        os.symlink("a.txt", self.repo / "link")
        r1 = self._run()
        os.remove(self.repo / "link")
        os.symlink("other", self.repo / "link")
        r2 = self._run()

        self.assertNotEqual(r1.stdout, r2.stdout)

    def test_broken_symlink(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        os.symlink("missing", self.repo / "broken")
        result = self._run()
        data = json.loads(result.stdout)
        self.assertTrue(data["dirty"])

    def test_diff_external_not_run(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        self._write("a.txt", b"modified")

        fake_diff = self.repo / "fake-diff.sh"
        fake_diff.write_text("#!/bin/sh\nexit 1\n")
        fake_diff.chmod(0o755)

        env = os.environ.copy()
        env["GIT_EXTERNAL_DIFF"] = str(fake_diff)
        env["GIT_CONFIG_GLOBAL"] = "/dev/null"
        env["GIT_CONFIG_SYSTEM"] = "/dev/null"
        env["GIT_OPTIONAL_LOCKS"] = "0"
        result = subprocess.run(
            [sys.executable, str(HELPER)],
            cwd=self.repo,
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(result.returncode, 0)
        data = json.loads(result.stdout)
        self.assertTrue(data["dirty"])
        self.assertNotEqual(
            data["candidate"],
            "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        )

    def test_subprocess_failure(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        original_run = candidate_id._run

        def failing_run(cmd, cwd=None):
            if cmd[0] == "git" and cmd[1] == "diff":
                raise candidate_id.CandidateError("injected failure")
            return original_run(cmd, cwd)

        candidate_id._run = failing_run
        try:
            with self.assertRaises(candidate_id.CandidateError):
                candidate_id.compute_candidate(cwd=str(self.repo))
        finally:
            candidate_id._run = original_run

    def test_same_status_content_drift(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        original_diff = candidate_id._tracked_diff
        calls = []

        def drifting_diff(repo, head, base=None):
            calls.append(None)
            if len(calls) == 1:
                return b"first diff"
            return b"second diff"

        candidate_id._tracked_diff = drifting_diff
        try:
            with self.assertRaises(candidate_id.CandidateError) as ctx:
                candidate_id.compute_candidate(cwd=str(self.repo))
            self.assertIn("changed during capture", str(ctx.exception))
        finally:
            candidate_id._tracked_diff = original_diff

    def test_invalid_base_fails(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        result = self._run("--base", "does-not-exist", "--head", "HEAD", check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_base_only_fails(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        result = self._run("--base", "HEAD", check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_noncommit_ref_fails(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        tree = subprocess.check_output(
            ["git", "rev-parse", "HEAD^{tree}"], cwd=self.repo, text=True
        ).strip()

        result = self._run("--base", tree, "--head", "HEAD", check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_non_repo_fails(self):
        nonrepo = TMP_ROOT / "not-a-repo"
        nonrepo.mkdir(exist_ok=True)
        try:
            result = self._run(cwd=nonrepo, check=False)
            self.assertNotEqual(result.returncode, 0)
        finally:
            shutil.rmtree(nonrepo, ignore_errors=True)

    def test_unborn_head_fails(self):
        result = self._run(check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_pr_scope_excludes_worktree_dirty(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")
        base = self._head()

        self._write("feature.txt", b"feature")
        self._git("add", "feature.txt")
        self._git("commit", "-m", "feature")
        head = self._head()

        r1 = self._run("--base", base, "--head", head)
        data1 = json.loads(r1.stdout)
        self.assertFalse(data1["dirty"])
        self.assertEqual(data1["scope"], "pr")
        self.assertIn("root", data1["excluded_from_hash"])
        self.assertIn("branch", data1["excluded_from_hash"])
        self.assertIn("dirty", data1["excluded_from_hash"])

        # Dirty the worktree; PR candidate must stay the same but dirty reports true.
        self._write("a.txt", b"dirty")
        r2 = self._run("--base", base, "--head", head)
        data2 = json.loads(r2.stdout)
        self.assertTrue(data2["dirty"])
        self.assertEqual(data1["candidate"], data2["candidate"])

    def test_pr_receipt_portable_across_clones(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")
        base = self._head()

        self._write("feature.txt", b"feature")
        self._git("add", "feature.txt")
        self._git("commit", "-m", "feature")
        head = self._head()

        r1 = self._run("--base", base, "--head", head)

        clone = self.repo.with_name(self.repo.name + "-clone")
        self.addCleanup(shutil.rmtree, clone, ignore_errors=True)
        subprocess.run(
            ["git", "clone", str(self.repo), str(clone)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        r2 = subprocess.run(
            [sys.executable, str(HELPER), "--base", base, "--head", head],
            cwd=clone,
            capture_output=True,
            text=True,
            check=True,
        )

        c1 = json.loads(r1.stdout)["candidate"]
        c2 = json.loads(r2.stdout)["candidate"]
        self.assertEqual(c1, c2)

    def test_nested_untracked_git_repo_fails(self):
        self._write("a.txt", b"hello")
        self._git("add", "a.txt")
        self._git("commit", "-m", "init")

        nested = self.repo / "nested-git"
        nested.mkdir()
        subprocess.run(
            ["git", "init"],
            cwd=nested,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        (nested / "file.txt").write_bytes(b"inside")

        result = self._run(check=False)
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()

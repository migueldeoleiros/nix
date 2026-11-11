"""Metadata-only discovery tests; never connect to a real keyring."""
import contextlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import Mock, patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "agent-secrets.py"
spec = importlib.util.spec_from_file_location("agent_secrets", SCRIPT)
cli = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cli)


class DiscoveryTests(unittest.TestCase):
    def invoke(self, *args):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = cli.main(["agent-secrets", *args])
        return code, out.getvalue(), err.getvalue()

    def discover(self, labels, *args):
        # Item interface deliberately has no secret-loading or unlocking methods.
        class Item:
            def __init__(self, label):
                self.label = label

            def get_label(self):
                return self.label

        service = Mock(spec=["search_sync"])
        service.search_sync.return_value = [Item(label) for label in labels]
        secret = Mock()
        secret.Service.get_sync.return_value = service
        schema, cancellable = object(), object()
        with patch.object(cli, "secret_api", return_value=(object(), secret, schema)), patch.object(
            cli, "cancellable_call", side_effect=lambda gio, timeout, callback: callback(cancellable)
        ):
            result = self.invoke(*args)
        secret.Service.get_sync.assert_called_once_with(secret.ServiceFlags.NONE, cancellable)
        service.search_sync.assert_called_once_with(schema, {}, secret.SearchFlags.ALL, cancellable)
        return result

    def test_list_sorted_valid_names_only_and_preserves_duplicates(self):
        result = self.discover(
            ["z-token", "asustor-sudo", "asustor-sudo", "UPPER", "bad\nname", "\x1b[31m",
             "-invalid", "a" * 65, "", None], "list"
        )
        self.assertEqual(result, (0, "asustor-sudo\nasustor-sudo\nz-token\n", ""))

    def test_search_case_insensitive_substring(self):
        self.assertEqual(
            self.discover(["nas-asustor-sudo", "gitea-token", "asustor-login"], "search", "ASUSTOR"),
            (0, "asustor-login\nnas-asustor-sudo\n", ""),
        )

    def test_no_matches_succeeds_without_output(self):
        self.assertEqual(self.discover(["gitea-token"], "search", "nas"), (0, "", ""))

    def test_invalid_search_rejected_before_keyring_access(self):
        with patch.object(cli, "secret_api") as api:
            for query in ["", "*", "a b", "a\n", "é", "a" * 65]:
                with self.subTest(query=query):
                    code, out, err = self.invoke("search", query)
                    self.assertEqual((code, out), (1, ""))
                    self.assertIn("invalid command or metadata", err)
            api.assert_not_called()

    def test_help_does_not_access_keyring(self):
        with patch.object(cli, "secret_api") as api:
            for args in [(), ("help",), ("--help",), ("-h",)]:
                code, out, err = self.invoke(*args)
                self.assertEqual((code, err), (0, ""))
                self.assertIn("search QUERY", out)
                self.assertIn("Application-only", out)
            api.assert_not_called()

    def test_keyring_error_does_not_print_exception_or_partial_names(self):
        with patch.object(cli, "secret_api", side_effect=RuntimeError("PRIVATE DETAIL")):
            self.assertEqual(self.invoke("list"), (1, "", "agent-secrets: keyring unavailable\n"))

    def test_invalid_command_shapes(self):
        with patch.object(cli, "secret_api") as api:
            for args in [("search",), ("list", "extra"), ("search", "nas", "extra")]:
                self.assertEqual(self.invoke(*args)[0], 1)
            api.assert_not_called()


if __name__ == "__main__":
    unittest.main()

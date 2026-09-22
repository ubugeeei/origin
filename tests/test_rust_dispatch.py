import importlib.util
from pathlib import Path
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "src/templates/nix/pkgs/rust-toolchain/dispatch.py"
module = importlib.util.spec_from_file_location("dispatch", SOURCE)
dispatch = importlib.util.module_from_spec(module)
module.loader.exec_module(dispatch)


class ToolchainSelection(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name).resolve()

    def test_vize_pin_preserves_wasm_targets_and_components(self):
        (self.directory / "rust-toolchain.toml").write_text(
            '[toolchain]\nchannel="1.98.0"\ncomponents=["rust-src", "clippy"]\n'
            'targets=["wasm32-unknown-unknown", "wasm32-wasip2"]\n'
        )
        child = self.directory / "crates/compiler"
        child.mkdir(parents=True)
        selected = dispatch.select_spec([], {}, child)
        self.assertEqual(selected["channel"], "1.98.0")
        self.assertEqual(selected["targets"], ["wasm32-unknown-unknown", "wasm32-wasip2"])
        self.assertIn("rust-src", selected["components"])

    def test_nested_nightly_overrides_parent_stable(self):
        (self.directory / "rust-toolchain").write_text("stable\n")
        child = self.directory / "uf"
        child.mkdir()
        (child / "rust-toolchain.toml").write_text(
            '[toolchain]\nchannel="nightly-2026-08-01"\nprofile="minimal"\n'
        )
        self.assertEqual(dispatch.project_spec(child), {"channel": "nightly-2026-08-01", "profile": "minimal"})

    def test_explicit_selector_beats_environment_and_is_consumed(self):
        arguments = ["+nightly-2026-08-01", "test", "--workspace"]
        selected = dispatch.select_spec(arguments, {"RUSTUP_TOOLCHAIN": "stable"}, self.directory)
        self.assertEqual(selected, {"channel": "nightly-2026-08-01"})
        self.assertEqual(arguments, ["test", "--workspace"])

    def test_cargo_subcommands_keep_parent_components(self):
        selected = dispatch.select_spec([], {
            "ORIGIN_RUST_TOOLCHAIN_SPEC": '{"channel":"nightly","components":["miri"]}',
            "RUSTUP_TOOLCHAIN": "stable",
        }, self.directory)
        self.assertEqual(selected, {"channel": "nightly", "components": ["miri"]})

    def test_explicit_local_compiler_path_is_relative_to_its_manifest(self):
        (self.directory / "rust-toolchain.toml").write_text('[toolchain]\npath="build/stage1"\n')
        self.assertEqual(dispatch.project_spec(self.directory)["path"], str(self.directory / "build/stage1"))

    def test_default_and_legacy_version_file(self):
        self.assertEqual(dispatch.project_spec(self.directory), dispatch.DEFAULT_SPEC)
        (self.directory / "rust-toolchain").write_text("1.77.2\n")
        self.assertEqual(dispatch.project_spec(self.directory), {"channel": "1.77.2"})


if __name__ == "__main__":
    unittest.main()

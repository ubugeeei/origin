"""Exercise the installed shell with the sparse environment used by GUI terminals."""
import json
import os
from pathlib import Path
import pty
import re
import select
import subprocess
import sys
import tempfile
import time
import unittest


BINARY = str(Path(sys.argv.pop(1)).resolve())


class ShellStartup(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name).resolve()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        for command in ("wt", "rtk"):
            file = self.bin / command
            file.write_text(f"#!/bin/sh\nprintf '{command}-from-nix\\n'\n")
            file.chmod(0o755)
        for directory in (".config/ush", "Library/Application Support/dev.ubugeeei.ush"):
            config = self.home / directory
            config.mkdir(parents=True)
            (config / "config.json").write_text(json.dumps({
                "aliases": {"cat": "unavailable-bat"},
                "shell": {"profileFiles": ["rc.sh"], "rcFiles": ["rc.sh"]},
            }))
            (config / "rc.sh").write_text(
                f'if [ -d "{self.bin}" ]; then export PATH="{self.bin}:/usr/bin:/bin"; fi\n'
            )
        config = Path(__file__).resolve().parents[1] / "src/templates/nix/home/shell/starship.toml"
        (self.home / ".config/starship.toml").write_text(config.read_text())
        self.env = {
            "HOME": str(self.home), "PATH": "/usr/bin:/bin",
            "TERM": "xterm-256color", "COLORTERM": "truecolor", "LANG": "en_US.UTF-8",
        }

    def test_login_restores_path_despite_cat_alias(self):
        result = subprocess.run(
            [BINARY, "-l", "-c", "wt --version; rtk --version"],
            env=self.env, cwd=self.home, text=True, capture_output=True, timeout=20,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["wt-from-nix", "rtk-from-nix"])
        self.assertNotIn("not found", result.stderr)

    def test_interactive_prompt_loads_xdg_config_and_status_colors(self):
        master, slave = pty.openpty()
        process = subprocess.Popen(
            [BINARY, "-l"], env=self.env, cwd=self.home,
            stdin=slave, stdout=slave, stderr=slave,
        )
        os.close(slave)
        output = bytearray()

        def read_until(needle):
            deadline = time.monotonic() + 20
            while needle not in output and time.monotonic() < deadline:
                if select.select([master], [], [], 0.2)[0]:
                    try:
                        output.extend(os.read(master, 65536))
                    except OSError:
                        break
                if process.poll() is not None:
                    break
            self.assertIn(needle, output, output.decode(errors="replace"))

        try:
            read_until("◠ ‿ ◠".encode())
            self.assertIn(b"38;2;123;184;172", output)
            self.assertIn(b"~", output)
            self.assertNotIn(b"\x1b]11;", output)
            visible = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", output.decode(errors="replace"))
            self.assertRegex(visible, r"~[^\n]*\n.*\( ◠ ‿ ◠\)و")
            child = self.home / "prompt-cd-check"
            child.mkdir()
            os.write(master, b"cd prompt-cd-check\r")
            read_until(b"~/prompt-cd-check")
            os.write(master, b"false\r")
            read_until(b"38;2;217;137;146")
        finally:
            process.terminate()
            process.wait(timeout=5)
            os.close(master)


if __name__ == "__main__":
    unittest.main()

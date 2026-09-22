#!@python@/bin/python3
"""Select project Rust toolchains from origin's locked Nix inputs."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tomllib

DEFAULT_SPEC = {
    "channel": "1.98.1",
    "components": ["rust-src", "rust-analyzer", "llvm-tools"],
    "targets": ["wasm32-unknown-unknown", "wasm32-wasip2"],
}


def project_spec(directory):
    for parent in (directory, *directory.parents):
        for name in ("rust-toolchain.toml", "rust-toolchain"):
            file = parent / name
            if file.is_file():
                content = file.read_text().strip()
                if name == "rust-toolchain" and not content.startswith("["):
                    return {"channel": content}
                spec = tomllib.loads(content)["toolchain"]
                if "path" in spec:
                    spec["path"] = str((parent / spec["path"]).resolve())
                return spec
    return DEFAULT_SPEC.copy()


def select_spec(arguments, environment, directory):
    if arguments and arguments[0].startswith("+"):
        return {"channel": arguments.pop(0)[1:]}
    if environment.get("ORIGIN_RUST_TOOLCHAIN_SPEC"):
        return json.loads(environment["ORIGIN_RUST_TOOLCHAIN_SPEC"])
    if environment.get("RUSTUP_TOOLCHAIN"):
        channel = environment["RUSTUP_TOOLCHAIN"]
        if Path(channel).is_absolute():
            return {"path": channel}
        # rustup commonly exports a host-qualified channel to subprocesses.
        return {"channel": re.sub(r"-@rustHost@$", "", channel)}
    return project_spec(directory)


def resolve_toolchain(spec):
    if "path" in spec:
        return Path(spec["path"])
    if spec == DEFAULT_SPEC:
        return Path("@defaultToolchain@")
    payload = json.dumps(spec, sort_keys=True)
    key = hashlib.sha256(("@expression@" + payload).encode()).hexdigest()
    state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    directory = state / "origin/rust-toolchains" / key
    toolchain = directory / "toolchain"
    if (toolchain / "bin/rustc").is_file():
        return toolchain.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    # Atomic replacement also handles concurrent first-use invocations.
    source = directory / f"spec-{os.getpid()}.json"
    source.write_text(payload)
    try:
        env = dict(os.environ, ORIGIN_RUST_SPEC=str(source))
        subprocess.run(
            ["@nix@/bin/nix", "build", "--impure", "--file", "@expression@",
             "--out-link", str(toolchain)],
            env=env, check=True, stdout=sys.stderr,
        )
    finally:
        source.unlink(missing_ok=True)
    return toolchain.resolve()


def main():
    command = Path(sys.argv[0]).name
    arguments = sys.argv[1:]
    spec = select_spec(arguments, os.environ, Path.cwd())
    if command == "cargo-miri" or (command == "cargo" and arguments[:1] == ["miri"]):
        spec["components"] = sorted(set(spec.get("components", [])) | {"miri", "rust-src"})
    toolchain = resolve_toolchain(spec)
    executable = toolchain / "bin" / command
    if not executable.is_file():
        raise RuntimeError(f"{command} is missing from {spec}; add its component to rust-toolchain.toml")
    environment = os.environ.copy()
    environment["PATH"] = str(toolchain / "bin") + os.pathsep + environment.get("PATH", "")
    # Cargo subprocesses must use this exact compiler, even with legacy rustup
    # proxies or an inherited RUSTUP_TOOLCHAIN in the caller's environment.
    environment.pop("RUSTUP_TOOLCHAIN", None)
    environment["ORIGIN_RUST_TOOLCHAIN_SPEC"] = json.dumps(spec)
    environment.setdefault("RUSTC", str(toolchain / "bin/rustc"))
    environment.setdefault("RUSTDOC", str(toolchain / "bin/rustdoc"))
    os.execve(executable, [str(executable), *arguments], environment)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"origin Rust: {error}", file=sys.stderr)
        sys.exit(1)

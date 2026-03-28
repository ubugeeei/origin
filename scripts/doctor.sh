#!/usr/bin/env nu

let repo_root = ($env.FILE_PWD | path join ".." | path expand)

def command-path [name: string] {
  try {
    which $name | get path.0
  } catch {
    null
  }
}

def vite-plus-which [name: string] {
  if (command-path "vp") == null {
    return null
  }

  try {
    let resolved = (
      ^vp env which $name
      | lines
      | each {|line| $line | str trim }
      | where {|line| $line != "" }
      | where {|line| $line | str starts-with "/" }
      | first
      | str trim
    )
    if ($resolved | is-empty) { null } else { $resolved }
  } catch {
    null
  }
}

def resolved-command-path [name: string] {
  let direct = (command-path $name)
  if $direct != null {
    return $direct
  }

  if $name == "node" {
    return (vite-plus-which "node")
  }

  null
}

def prepend-path [entry: string] {
  let kind = ($entry | path type)
  if $kind == "dir" or $kind == "file" {
    $env.PATH = ([$entry] | append ($env.PATH | where {|current| $current != $entry }))
  }
}

def main [] {
  let cargo_home = ([$env.HOME ".cargo"] | path join)
  let go_home = ([$env.HOME "go"] | path join)
  let go_bin = ([$go_home "bin"] | path join)
  let bun_home = ([$env.HOME ".bun"] | path join)
  let mise_shims = ([$env.HOME ".local" "share" "mise" "shims"] | path join)
  let pnpm_home = ([$env.HOME "Library" "pnpm"] | path join)
  let hm_home_path = ([$env.HOME ".local" "state" "nix" "profiles" "home-manager" "home-path" "bin"] | path join)

  $env.CARGO_HOME = $cargo_home
  $env.GOPATH = $go_home
  $env.GOBIN = $go_bin
  $env.BUN_INSTALL = $bun_home
  $env.PNPM_HOME = $pnpm_home

  let candidate_paths = [
    ([$env.HOME ".vite-plus" "bin"] | path join)
    ([$env.HOME ".local" "bin"] | path join)
    $mise_shims
    ([$cargo_home "bin"] | path join)
    $go_bin
    ([$bun_home "bin"] | path join)
    $pnpm_home
    $hm_home_path
    ($repo_root | path join "result" "sw" "bin")
  ]

  for entry in $candidate_paths {
    prepend-path $entry
  }

  let primary_user = (^id -un | str trim)
  let login_shell = (
    try {
      ^/usr/bin/dscl . -read $"/Users/($primary_user)" UserShell
      | parse "{key}: {value}"
      | get value.0
    } catch {
      "<unset>"
    }
  )
  let launchd_shell = (
    try {
      let value = (^/bin/launchctl getenv SHELL | str trim)
      if ($value | is-empty) { "<unset>" } else { $value }
    } catch {
      "<unset>"
    }
  )
  let launchd_path = (
    try {
      let value = (^/bin/launchctl getenv PATH | str trim)
      if ($value | is-empty) { "<unset>" } else { $value }
    } catch {
      "<unset>"
    }
  )

  print $"info login shell -> ($login_shell)"
  print $"info launchd SHELL -> ($launchd_shell)"
  print $"info launchd PATH -> ($launchd_path)"

  for cmd in [nix darwin-rebuild git gh glab gam zed ghostty nu tmux codex aws mise vp node moon moonfmt moonc moonbit-lsp cargo cargo-clippy clippy-driver rustc rustfmt rust-analyzer go gopls gofumpt goimports golangci-lint dlv fastfetch atuin carapace] {
    let path = (resolved-command-path $cmd)
    if $path == null {
      print $"miss ($cmd)"
    } else {
      print $"ok   ($cmd) -> ($path)"
    }
  }

  let optional_commands = [
    { cmd: "pnpm", home: $pnpm_home }
    { cmd: "bun", home: ([$bun_home "bin"] | path join "bun") }
  ]

  for optional in $optional_commands {
    let path = (resolved-command-path $optional.cmd)
    if $path != null {
      print $"ok   ($optional.cmd) -> ($path)"
    } else {
      print $"skip ($optional.cmd) -> optional"
    }
  }
}

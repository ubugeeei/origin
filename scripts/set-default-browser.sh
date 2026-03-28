#!/usr/bin/env nu

const script_name = "set-default-browser.sh"

def fail [message: string, code: int = 1] {
  print --stderr $message
  exit $code
}

def command-path [name: string] {
  try {
    which $name | get path.0
  } catch {
    null
  }
}

def prepend-path [entry: string] {
  if (($entry | path type) == "dir") {
    $env.PATH = ([$entry] | append ($env.PATH | where {|current| $current != $entry }))
  }
}

def main [browser?: string] {
  if $browser == null {
    print --stderr $"usage: ($script_name) <browser>"
    print --stderr $"example: ($script_name) dia"
    exit 1
  }

  prepend-path ([$env.HOME ".local" "bin"] | path join)
  prepend-path ([$env.HOME ".local" "state" "nix" "profiles" "home-manager" "home-path" "bin"] | path join)

  let defaultbrowser = (command-path "defaultbrowser")
  if $defaultbrowser == null {
    fail "defaultbrowser is not installed"
  }

  run-external $defaultbrowser $browser
}

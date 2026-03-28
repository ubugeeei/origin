#!/usr/bin/env nu

let repo_root = ($env.FILE_PWD | path join ".." | path expand)

def fail [message: string, code: int = 1] {
  print --stderr $message
  exit $code
}

def main [] {
  try {
    ^xcode-select -p | ignore
  } catch {
    fail "Install Command Line Tools first with: xcode-select --install"
  }

  cd $repo_root

  if ((($repo_root | path join ".git") | path type) != "dir") {
    run-external git init
  }

  run-external git add .
  run-external git status --short
}

#!/usr/bin/env nu

const usage_text = "
usage:
  clone github <owner>/<repo> [alias]
  clone gitlab <group>/<repo> [alias]
  clone github.com/<owner>/<repo> [alias]
  clone git@github.com:<owner>/<repo>.git [alias]

options:
  -a, --alias <name>  clone into <repo>--<name>
  -h, --help          show this help

notes:
  - only GitHub and GitLab are supported
  - only SSH remotes are accepted
  - repositories are cloned under $GHQ_ROOT or $HOME/Source
"

def fail [message: string, code: int = 64] {
  print --stderr $"clone: ($message)"
  exit $code
}

def print-usage [] {
  print --stderr ($usage_text | str trim)
}

def maybe-normalize-host [host: string] {
  match $host {
    "github" => "github.com"
    "github.com" => "github.com"
    "gitlab" => "gitlab.com"
    "gitlab.com" => "gitlab.com"
    _ => null
  }
}

def parse-ssh-url [spec: string] {
  let parsed = ($spec | parse --regex '^git@(?<host>github\.com|gitlab\.com):(?<slug>.+)$')
  if ($parsed | is-empty) {
    null
  } else {
    let match = ($parsed | get 0)
    { host: $match.host, slug: $match.slug }
  }
}

def parse-spec [spec: string] {
  let ssh_match = (parse-ssh-url $spec)
  if $ssh_match != null {
    return $ssh_match
  }

  if ($spec | str starts-with "http://") or ($spec | str starts-with "https://") {
    fail "only SSH remotes are supported"
  }

  if not ($spec | str contains "/") {
    return null
  }

  let parts = ($spec | split row "/")
  let host_part = ($parts | first)
  let slug_part = ($parts | skip 1 | str join "/")
  let normalized_host = (maybe-normalize-host $host_part)

  if $normalized_host == null {
    fail $"unsupported host: ($host_part)"
  }

  { host: $normalized_host, slug: $slug_part }
}

def validate-slug [slug: string] {
  let cleaned = ($slug | str trim --char "/" | str replace --regex '\.git$' "")

  if ($cleaned | is-empty) {
    fail "repository path is required"
  }

  if not ($cleaned | str contains "/") {
    fail "repository path must look like <owner>/<repo>"
  }

  for part in ($cleaned | split row "/") {
    if ($part | is-empty) {
      fail "repository path contains an empty segment"
    }

    if $part == "." or $part == ".." {
      fail $"repository path contains an invalid segment: ($part)"
    }
  }

  $cleaned
}

def validate-alias [alias_name: string] {
  if ($alias_name | is-empty) {
    fail "alias must not be empty"
  }

  if ($alias_name | str contains "/") {
    fail "alias must not contain '/'"
  }

  if $alias_name == "." or $alias_name == ".." {
    fail "alias must not be '.' or '..'"
  }
}

def command-path [name: string] {
  try {
    which $name | get path.0
  } catch {
    null
  }
}

def main [--alias (-a): string, ...args: string] {
  mut host = ""
  mut slug = ""
  mut alias_name = ($alias | default "")

  match ($args | length) {
    1 => {
      let parsed = (parse-spec ($args | get 0))
      if $parsed == null {
        print-usage
        fail "missing host or repository path"
      }

      $host = $parsed.host
      $slug = $parsed.slug
    }
    2 => {
      let first = ($args | get 0)
      let second = ($args | get 1)
      let normalized_host = (maybe-normalize-host $first)

      if $normalized_host != null {
        $host = $normalized_host
        $slug = $second
      } else {
        if not ($alias_name | is-empty) {
          fail "alias specified twice"
        }

        let parsed = (parse-spec $first)
        if $parsed == null {
          print-usage
          fail "missing host or repository path"
        }

        $host = $parsed.host
        $slug = $parsed.slug
        $alias_name = $second
      }
    }
    3 => {
      let normalized_host = (maybe-normalize-host ($args | get 0))
      if $normalized_host == null {
        fail $"unsupported host: (($args | get 0))"
      }

      if not ($alias_name | is-empty) {
        fail "alias specified twice"
      }

      $host = $normalized_host
      $slug = ($args | get 1)
      $alias_name = ($args | get 2)
    }
    _ => {
      print-usage
      fail "unexpected arguments"
    }
  }

  $slug = (validate-slug $slug)

  if not ($alias_name | is-empty) {
    validate-alias $alias_name
  }

  let slug_parts = ($slug | split row "/")
  let repo_name = ($slug_parts | last)
  let namespace = ($slug_parts | first (($slug_parts | length) - 1) | str join "/")
  let local_name = if ($alias_name | is-empty) {
    $repo_name
  } else {
    $"($repo_name)--($alias_name)"
  }

  let root = ($env | get -o GHQ_ROOT | default ([$env.HOME "Source"] | path join))
  let target = ([$root $host $namespace $local_name] | path join)
  let remote = $"git@($host):($slug).git"

  if $host != "github.com" and $host != "gitlab.com" {
    fail "only github.com and gitlab.com are supported"
  }

  if (($target | path type) != null) {
    fail $"target already exists: ($target)"
  }

  let git = (command-path "git")
  if $git == null {
    fail "git is not installed"
  }

  mkdir ($target | path dirname)

  print $"cloning ($remote)"
  print $"  -> ($target)"

  run-external $git clone $remote $target
}

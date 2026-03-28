#!/usr/bin/env nu

let repo_root = ($env.FILE_PWD | path join ".." | path expand)

def fail [message: string, code: int = 1] {
  print --stderr $message
  exit $code
}

def detect-username [] {
  try {
    ^gh api user --jq .login | str trim
  } catch {
    fail "username is required when gh is not authenticated"
  }
}

def main [username?: string] {
  let username = if $username == null {
    detect-username
  } else {
    $username
  }

  let target_dir = ($repo_root | path join "assets" "profile-icons" "github" $username)
  let target_file = ($target_dir | path join "avatar.jpg")
  let tmp_image = (^mktemp | str trim)

  mkdir $target_dir

  let avatar_url = (
    http get $"https://api.github.com/users/($username)"
    | get avatar_url
  )

  http get --raw $avatar_url | save --raw --force $tmp_image

  let mime_type = (^/usr/bin/file -b --mime-type $tmp_image | str trim)
  if $mime_type != "image/jpeg" {
    rm -f $tmp_image
    fail $"expected image/jpeg from GitHub avatar, got ($mime_type)"
  }

  mv -f $tmp_image $target_file

  let sha256 = (
    ^/usr/bin/shasum -a 256 $target_file
    | parse --regex '^(?<sha>[0-9a-f]+)\s+.+$'
    | get sha.0
  )

  print $"saved ($username) avatar to ($target_file)"
  print $"source: https://github.com/($username)"
  print $"sha256: ($sha256)"
}

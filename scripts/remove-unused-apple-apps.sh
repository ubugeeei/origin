#!/usr/bin/env nu

def main [] {
  let removable_apps = [
    "/Applications/GarageBand.app"
    "/Applications/iMovie.app"
    "/Applications/Keynote.app"
    "/Applications/Numbers.app"
    "/Applications/Pages.app"
  ]

  let protected_apps = [
    "/System/Applications/Books.app"
    "/System/Applications/Chess.app"
    "/System/Applications/FaceTime.app"
    "/System/Applications/Games.app"
    "/System/Applications/Journal.app"
    "/System/Applications/Music.app"
  ]

  let existing_removable = ($removable_apps | where {|app| ($app | path exists) })
  let existing_protected = ($protected_apps | where {|app| ($app | path exists) })

  print "Removable Apple apps not used in this workstation setup:"
  for app in $existing_removable {
    print $"  - ($app)"
  }

  print ""
  print "SIP-protected Apple apps requested for removal but not removable while SIP is enabled:"
  for app in $existing_protected {
    print $"  - ($app)"
  }

  if ($existing_removable | is-empty) {
    print ""
    print "No removable apps were found."
    return
  }

  print ""
  print "Removing only the removable apps in /Applications..."
  run-external sudo rm -rf ...$existing_removable
  print "Done."
}

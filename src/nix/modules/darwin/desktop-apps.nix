{ config, pkgs, ... }:
let
  appEnv = pkgs.buildEnv {
    name = "nix-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" "/Library/Input Methods" ];
  };
  exposedApps = [
    "Discord.app"
    "Ghostty.app"
    "Gmail.app"
    "Google Calendar.app"
    "Google Chrome.app"
    "Karabiner-Elements.app"
    "Microsoft Edge.app"
    "Obsidian.app"
    "Raycast.app"
    "Slack.app"
    "Spotify.app"
    "Twitter.app"
    "Visual Studio Code.app"
    "Zed.app"
    "azooKeyMac.app"
    "zoom.us.app"
  ];
  exposedAppsScript = pkgs.lib.concatMapStringsSep "\n" (app: ''  "${app}"'') exposedApps;
in
{
  environment.systemPackages = with pkgs; [
    azookey-mac
    gmail-app
    google-calendar-app
    twitter-app
    microsoft-edge-mac
    raycast
    ghostty-bin
    zed-editor
    vscode
    discord
    google-chrome
    obsidian
    slack
    spotify
    zoom-us
  ];

  # Expose Nix-managed GUI apps in a normal macOS Applications folder.
  system.activationScripts.applications.text = pkgs.lib.mkForce ''
    echo "Setting up /Applications..." >&2
    managed_root_manifest="/Applications/.nix-managed-apps"
    lsregister='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
    allowed_apps=(
${exposedAppsScript}
    )

    if [ -f "$managed_root_manifest" ]; then
      while IFS= read -r app_name; do
        [ -n "$app_name" ] || continue
        rm -rf "/Applications/$app_name"
      done < "$managed_root_manifest"
    fi

    : > "$managed_root_manifest"
    rm -rf /Applications/Nix\ Apps
    find ${appEnv}/Applications -maxdepth 1 -type l | while read -r app; do
      src="$(readlink "$app")"
      app_name="$(basename "$src")"
      should_expose=0
      for allowed in "''${allowed_apps[@]}"; do
        if [ "$app_name" = "$allowed" ]; then
          should_expose=1
          break
        fi
      done
      [ "$should_expose" -eq 1 ] || continue
      rm -rf "/Applications/$app_name"
      /usr/bin/ditto "$src" "/Applications/$app_name"
      echo "$app_name" >> "$managed_root_manifest"
      "$lsregister" -f "/Applications/$app_name" >/dev/null 2>&1 || true
    done

    /usr/bin/killall Dock >/dev/null 2>&1 || true
  '';

  system.activationScripts.inputMethods.text = pkgs.lib.mkAfter ''
    echo "Setting up /Library/Input Methods..." >&2
    mkdir -p /Library/Input\ Methods
    find ${appEnv}/Library/Input\ Methods -maxdepth 1 -type l | while read -r im; do
      src="$(readlink "$im")"
      im_name="$(basename "$src")"
      rm -rf "/Library/Input Methods/$im_name"
      /usr/bin/ditto "$src" "/Library/Input Methods/$im_name"
    done
  '';
}

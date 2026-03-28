{ config, machine, pkgs, username, mkShellEnvironment, ... }:
let
  shellEnv = mkShellEnvironment {
    homeDir = machine.homeDirectory;
    inherit username;
  };
in
{
  nixpkgs.config.allowUnfree = true;

  nix.enable = false;

  users.users.${username} = {
    home = machine.homeDirectory;
    shell = pkgs.nushell;
  };

  system.primaryUser = username;

  networking = machine.networking;

  environment.shells = with pkgs; [
    bashInteractive
    nushell
    zsh
  ];

  fonts.packages = with pkgs; [
    nova-font
  ];

  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.trackpad.scaling" = 3.0;
    };

    CustomUserPreferences = {
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 3.0;
      };

      "com.apple.assistant.support" = {
        "Assistant Enabled" = false;
      };

      "com.apple.Siri" = {
        StatusMenuVisible = false;
      };

      # In common macOS Kotoeri defaults, `3` corresponds to the `．，` style.
      "com.apple.inputmethod.Kotoeri" = {
        JIMPrefPunctuationTypeKey = 3;
      };
    };

    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
  };

  security.pam.services.sudo_local.enable = machine.security.touchIdSudoAuth;
  security.pam.services.sudo_local.touchIdAuth = machine.security.touchIdSudoAuth;

  launchd.user.envVariables = shellEnv.launchdEnvVariables;

  launchd.user.agents.ghostty-quick-terminal = {
    serviceConfig.ProgramArguments = [
      "/usr/bin/open"
      "-gj"
      "-a"
      "Ghostty.app"
    ];
    serviceConfig.RunAtLoad = true;
  };

  services.karabiner-elements.enable = true;

  environment.userLaunchAgents."org.pqrs.karabiner.agent.karabiner_grabber.plist".enable =
    pkgs.lib.mkForce false;
  environment.userLaunchAgents."org.pqrs.karabiner.agent.karabiner_observer.plist".enable =
    pkgs.lib.mkForce false;
  environment.userLaunchAgents."org.pqrs.karabiner.karabiner_console_user_server.plist".enable =
    pkgs.lib.mkForce false;
  environment.userLaunchAgents."org.pqrs.service.agent.karabiner_console_user_server.plist".source =
    "${config.services.karabiner-elements.package}/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements Non-Privileged Agents v2.app/Contents/Library/LaunchAgents/org.pqrs.service.agent.karabiner_console_user_server.plist";

  system.activationScripts.ensureUserToolOwnership.text = pkgs.lib.mkAfter ''
    user_group="$(/usr/bin/id -gn ${username})"

    for path in "${machine.homeDirectory}/go" "${machine.homeDirectory}/.cargo"; do
      if [ ! -e "$path" ]; then
        continue
      fi

      current_owner="$(/usr/bin/stat -f '%Su' "$path" 2>/dev/null || true)"
      if [ "$current_owner" != "${username}" ]; then
        echo "Fixing ownership for $path..." >&2
        /usr/sbin/chown -R "${username}:$user_group" "$path"
      fi
    done
  '';

  system.activationScripts.postActivation.text = pkgs.lib.mkAfter ''
    target_shell="${shellEnv.loginShell}"
    current_shell="$(/usr/bin/dscl . -read /Users/${username} UserShell 2>/dev/null | /usr/bin/awk '{print $2}')"

    if ! /usr/bin/grep -qx "$target_shell" "$systemConfig/etc/shells"; then
      echo "Skipping login shell update because $target_shell is not in the managed shells list." >&2
    elif [ "$current_shell" != "$target_shell" ]; then
      echo "Setting login shell for ${username} to $target_shell..." >&2
      /usr/bin/dscl . -create /Users/${username} UserShell "$target_shell"
    fi
  '';

  system.stateVersion = 6;
}

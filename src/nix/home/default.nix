{ config, lib, machine, pkgs, username, mkShellEnvironment, ... }:
let
  homeDir = machine.homeDirectory;
  shellEnv = mkShellEnvironment {
    inherit homeDir username;
  };
  workspaceRoot = shellEnv.workspaceRoot;
  legacyWorkspaceRoot = "${homeDir}/Code";
  repositoryTools = pkgs.runCommand "repository-tools" { } ''
    mkdir -p "$out"
    cp ${../../workspace/repos.sh} "$out/repos.sh"
    cp ${../../workspace/metadata.jq} "$out/metadata.jq"
    cp ${../../workspace/Workspace.pkl} "$out/Workspace.pkl"
  '';
  repositoryCommand = command: ''
    #!${pkgs.bash}/bin/bash
    export WORKSPACE_PKL=${pkgs.pkl}/bin/pkl
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.jq pkgs.git pkgs.openssh ]}:$PATH"
    exec ${pkgs.bash}/bin/bash ${repositoryTools}/repos.sh ${command} "$@"
  '';
  raycastLauncher = "${homeDir}/.local/bin/launch-raycast";
  raycastWindowCommandLauncher = "${homeDir}/.local/bin/launch-raycast-window-command";
  sourceTerminalEnv = ''
    terminal_env="$HOME/.config/workstation/shell/terminal-env.sh"
    if [ -f "$terminal_env" ]; then
      # shellcheck disable=SC1090
      . "$terminal_env"
    fi
  '';
  mkManagedWrapper = target: ''
    #!${pkgs.bash}/bin/bash
    ${sourceTerminalEnv}
    exec ${target} "$@"
  '';
  vpWrapper = ''
    #!${pkgs.bash}/bin/bash
    ${sourceTerminalEnv}
    user_vp="$HOME/.vite-plus/current/bin/vp"
    if [ -x "$user_vp" ]; then
      exec "$user_vp" "$@"
    fi
    exec ${pkgs.vite-plus}/bin/vp "$@"
  '';
  ushWrapper = ''
    #!${pkgs.bash}/bin/bash
    ${sourceTerminalEnv}
    local_ush="${workspaceRoot}/github.com/ubugeeei/ush/target/release/ush"
    legacy_local_ush="$HOME/Code/github.com/ubugeeei/ush/target/release/ush"
    if [ -x "$local_ush" ]; then
      exec "$local_ush" "$@"
    fi
    if [ -x "$legacy_local_ush" ]; then
      exec "$legacy_local_ush" "$@"
    fi
    exec ${pkgs.ush}/bin/ush "$@"
  '';
  hhkbVendorId = 1278;
  hhkbProductId = 33;
  hhkbBluetoothAddress = "FB:D5:C8:03:85:A6";
  commonShellAliases = {
    c = "clear";
    cat = "bat";
    df = "duf";
    du = "dust";
    g = "git";
    ga = "git add";
    gaa = "git add --all";
    gam = "git commit --amend";
    gb = "git branch";
    gbda = "git gbda";
    gco = "git checkout";
    gd = "git diff";
    gf = "git fetch";
    gl = "git pull";
    gm = "git commit -m";
    gp = "git push";
    gs = "git status -sb";
    gsw = "git switch";
    l = "eza -lah --git";
    lg = "eza -lah --git";
    ll = "eza -lah --git";
    lt = "eza --tree --level=2";
    t = "tmux attach -t main || tmux new -s main";
    v = "nvim";
    vc = "code";
    vpc = "vp check";
    vpd = "vp dev";
    vpt = "vp test";
    ze = "zed";
  };
  ushShellAliases = builtins.removeAttrs commonShellAliases [
    "g"
    "gm"
    "gam"
  ];
  ushRc = ''
    if [ -f "$HOME/.config/workstation/shell/terminal-env.sh" ]; then
      . "$HOME/.config/workstation/shell/terminal-env.sh"
    fi
  '';
  interactiveUshPath = "${homeDir}/.local/bin/ush";
  ushConfig = builtins.toJSON {
    shell = {
      historySize = 1000000;
      interaction = true;
      rcFiles = [ "rc.sh" ];
      stylishDefault = false;
    };
    aliases = ushShellAliases;
  };
  ghosttyConfig = ''
    command = ${interactiveUshPath}
    env = XDG_CONFIG_HOME=${homeDir}/.config
    env = XDG_CACHE_HOME=${homeDir}/.cache
    env = XDG_DATA_HOME=${homeDir}/.local/share
    env = XDG_STATE_HOME=${homeDir}/.local/state
    font-family = Menlo
    font-family = "JetBrainsMono Nerd Font Mono"
    font-size = 15
    keybind = global:shift+space=toggle_quick_terminal
    keybind = shift+enter=text:\x1b\r
    macos-option-as-alt = true
    quick-terminal-animation-duration = 0
    quick-terminal-position = left
    quick-terminal-screen = main
    quick-terminal-size = 50%
    shell-integration = detect
    theme = "GitHub Dark High Contrast"
    window-inherit-working-directory = true
    window-padding-x = 12
    window-padding-y = 12
  '';
  mkKarabinerShellCommandRule =
    {
      description,
      keyCode,
      mandatoryModifiers,
      shellCommand,
    }:
    {
      inherit description;
      manipulators = [
        {
          type = "basic";
          from = {
            key_code = keyCode;
            modifiers = {
              mandatory = mandatoryModifiers;
              optional = [ ];
            };
          };
          to = [
            {
              shell_command = shellCommand;
            }
          ];
        }
      ];
    };
  karabinerConfig = builtins.toJSON {
    global = {
      check_for_updates_on_startup = false;
      show_in_menu_bar = true;
      show_profile_name_in_menu_bar = false;
    };
    profiles = [
      {
        complex_modifications = {
          parameters = {
            basic.to_delayed_action_delay_milliseconds = 500;
            basic.to_if_alone_timeout_milliseconds = 1000;
            basic.to_if_held_down_threshold_milliseconds = 500;
            basic.simultaneous_threshold_milliseconds = 50;
            mouse_motion_to_scroll.speed = 100;
          };
          rules = [
            (mkKarabinerShellCommandRule {
              description = "Launch Raycast with Command+Space";
              keyCode = "spacebar";
              mandatoryModifiers = [ "command" ];
              shellCommand = raycastLauncher;
            })
            # Keep native macOS Option+Arrow text navigation and selection available.
            (mkKarabinerShellCommandRule {
              description = "Raycast window management: left half with Control+Option+Left";
              keyCode = "left_arrow";
              mandatoryModifiers = [
                "control"
                "option"
              ];
              shellCommand = "${raycastWindowCommandLauncher} left-half";
            })
            (mkKarabinerShellCommandRule {
              description = "Raycast window management: right half with Control+Option+Right";
              keyCode = "right_arrow";
              mandatoryModifiers = [
                "control"
                "option"
              ];
              shellCommand = "${raycastWindowCommandLauncher} right-half";
            })
            (mkKarabinerShellCommandRule {
              description = "Raycast window management: maximize width with Control+Option+Up";
              keyCode = "up_arrow";
              mandatoryModifiers = [
                "control"
                "option"
              ];
              shellCommand = "${raycastWindowCommandLauncher} maximize-width";
            })
            (mkKarabinerShellCommandRule {
              description = "Raycast window management: restore with Control+Option+Down";
              keyCode = "down_arrow";
              mandatoryModifiers = [
                "control"
                "option"
              ];
              shellCommand = "${raycastWindowCommandLauncher} restore";
            })
          ];
        };
        devices = [
          {
            disable_built_in_keyboard_if_exists = true;
            fn_function_keys = [ ];
            identifiers = {
              device_address = hhkbBluetoothAddress;
              is_keyboard = true;
              is_pointing_device = false;
              product_id = hhkbProductId;
              vendor_id = hhkbVendorId;
            };
            ignore = false;
            manipulate_caps_lock_led = false;
            simple_modifications = [ ];
            treat_as_built_in_keyboard = false;
          }
        ];
        fn_function_keys = [ ];
        name = "Default profile";
        parameters = {
          delay_milliseconds_before_open_device = 1000;
        };
        selected = true;
        simple_modifications = [ ];
        virtual_hid_keyboard = {
          caps_lock_delay_milliseconds = 0;
          country_code = 0;
          indicate_sticky_modifier_keys_state = true;
          keyboard_type_v2 = "ansi";
        };
      }
    ];
  };
in
{
  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "25.05";

  imports = [
    ({ config, lib, machine, pkgs, ... }: import ../../../generated/home/git.nix {
      inherit config lib machine pkgs;
    })
    ({ config, lib, pkgs, ... }: import ../../../generated/home/shell.nix {
      inherit config lib pkgs;
    })
    ({ config, lib, pkgs, ... }: import ../../../generated/home/editor.nix {
      inherit config lib pkgs;
    })
    ({ config, lib, pkgs, ... }: import ../../../generated/home/devtools.nix {
      inherit config lib pkgs;
    })
  ];

  home.packages = with pkgs; [
    awscli2
    bun
    codex
    colima
    defaultbrowser
    docker-client
    docker-compose
    ghq
    gcal-open
    gmail-open
    glab
    jq
    just
    lazydocker
    ripgrep
    moonbit
    fd
    eza
    bat
    delta
    dust
    duf
    bottom
    gam
    procs
    sd
    choose
    cargo
    cargo-edit
    clippy
    delve
    vite-plus
    go
    gofumpt
    golangci-lint
    gopls
    (lib.lowPrio gotools)
    rust-analyzer
    xh
    yq-go
    zig
    rustc
    rustfmt
  ];

  home.sessionVariables = shellEnv.sessionVariables;
  home.sessionPath = shellEnv.managedPathEntries;

  home.shellAliases = commonShellAliases;

  home.activation.createWorkspaceLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${workspaceRoot}"
    mkdir -p "$HOME/.local/bin"

    ensure_workspace_host_layout() {
      local host="$1"
      local target="${workspaceRoot}/$host"
      local legacy="${legacyWorkspaceRoot}/$host"

      if [ -L "$target" ] || [ -d "$target" ]; then
        return
      fi

      if [ -d "$legacy" ]; then
        ln -s "$legacy" "$target"
      else
        mkdir -p "$target"
      fi
    }

    ensure_workspace_host_layout github.com
    ensure_workspace_host_layout gitlab.com
  '';

  home.activation.createLanguageToolDirs = lib.hm.dag.entryAfter [ "createWorkspaceLayout" ] ''
    mkdir -p "$HOME/.cargo/bin"
    mkdir -p "$HOME/go/bin"
    mkdir -p "$HOME/go/pkg"
    mkdir -p "$HOME/go/src"
    mkdir -p "$HOME/.moon/bin"
  '';

  home.activation.setupVitePlus = lib.hm.dag.entryAfter [ "createLanguageToolDirs" ] ''
    vite_plus_home="$HOME/.vite-plus"
    mkdir -p "$vite_plus_home/current/bin"
    ln -sfn "${pkgs.vite-plus}/bin/vp" "$vite_plus_home/current/bin/vp"
    cat > "$vite_plus_home/current/package.json" <<'EOF'
    {
      "name": "vp-global-nix",
      "private": true
    }
    EOF
    ${pkgs.vite-plus}/bin/vp env setup >/dev/null
    ${pkgs.vite-plus}/bin/vp env on >/dev/null
  '';

  home.activation.installClaudeCode = lib.hm.dag.entryAfter [ "setupVitePlus" ] ''
    if [ ! -x "$HOME/.local/bin/claude" ]; then
      ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash
    fi
  '';

  home.activation.installRtk = lib.hm.dag.entryAfter [ "installClaudeCode" ] ''
    if [ ! -x "$HOME/.local/bin/rtk" ]; then
      ${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | RTK_INSTALL_DIR="$HOME/.local/bin" ${pkgs.bash}/bin/bash
    fi
  '';

  home.activation.installAzooKeyUser = lib.hm.dag.entryAfter [ "setupVitePlus" ] ''
    mkdir -p "$HOME/Library/Input Methods"
    if [ -e "$HOME/Library/Input Methods/azooKeyMac.app" ]; then
      chmod -R u+w "$HOME/Library/Input Methods/azooKeyMac.app" || true
      rm -rf "$HOME/Library/Input Methods/azooKeyMac.app"
    fi
    /usr/bin/ditto "${pkgs.azookey-mac}/Library/Input Methods/azooKeyMac.app" "$HOME/Library/Input Methods/azooKeyMac.app"
  '';

  home.activation.cleanupLegacyAppMirrors = lib.hm.dag.entryAfter [ "installAzooKeyUser" ] ''
    rm -rf "$HOME/Applications/Nix Apps"
    rmdir "$HOME/Applications/Home Manager Apps" 2>/dev/null || true
  '';

  home.activation.disableSpotlightHotkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    plist="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
    mkdir -p "$HOME/Library/Preferences"
    if [ ! -f "$plist" ]; then
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict
    fi

    ensure_disabled() {
      local key="$1"
      /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$key dict" "$plist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:$key:enabled" "$plist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$key:enabled integer 0" "$plist"
    }

    ensure_disabled 64
    ensure_disabled 65
    /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
  '';

  xdg.enable = true;

  home.file."${config.xdg.configHome}/starship.toml".force = true;

  xdg.configFile."ghq/config.yml".text = ''
    root: ${workspaceRoot}
  '';

  xdg.configFile."glab-cli/config.yml".text = ''
    git_protocol: ssh
    browser: open
    editor: zed
    pager: delta
  '';

  xdg.configFile."docker/config.json".text = builtins.toJSON {
    detachKeys = "ctrl-e,e";
  };

  xdg.configFile."ush/config.json".text = ushConfig;
  xdg.configFile."ush/rc.sh".text = ushRc;

  # ush resolves its macOS config via ProjectDirs under Library/Application Support.
  home.file."Library/Application Support/dev.ubugeeei.ush/config.json".text = ushConfig;
  home.file."Library/Application Support/dev.ubugeeei.ush/rc.sh".text = ushRc;

  xdg.configFile."ghostty/config".text = ghosttyConfig;

  # Ghostty on macOS also looks under Application Support when XDG variables
  # are not yet present in the app launch environment.
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    force = true;
    text = ghosttyConfig;
  };

  xdg.configFile."karabiner/karabiner.json".text = karabinerConfig;

  xdg.configFile."nix/README.md".text = ''
    Place custom package overlays here later if you decide to package Dia or other workstation assets.
  '';

  home.file.".config/workstation/shell/terminal-env.sh".text = ''
    export SHELL="${interactiveUshPath}"

    prepend_path() {
      case ":''${PATH:-}:" in
        *":$1:"*) ;;
        *)
          if [ -n "''${PATH:-}" ]; then
            PATH="$1:$PATH"
          else
            PATH="$1"
          fi
          export PATH
          ;;
      esac
    }

    ${builtins.concatStringsSep "\n" (map (path: "prepend_path \"${path}\"") (lib.reverseList shellEnv.managedPathEntries))}

    # Some embedded terminals start shells without TERM. Fall back so terminfo
    # consumers like clear, tput, fzf, and tmux can still work.
    if [ -z "''${TERM:-}" ]; then
      if [ -n "''${TMUX:-}" ]; then
        export TERM="screen-256color"
      else
        export TERM="xterm-256color"
      fi
    fi

    if [ -z "''${COLORTERM:-}" ]; then
      export COLORTERM="truecolor"
    fi
  '';

  home.file.".local/bin/ush" = {
    executable = true;
    force = true;
    text = ushWrapper;
  };

  home.file.".local/bin/zed" = {
    executable = true;
    text = mkManagedWrapper "${pkgs.zed-editor}/bin/zeditor";
  };

  home.file.".local/bin/code" = {
    executable = true;
    text = mkManagedWrapper "${pkgs.vscode}/bin/code";
  };

  home.file.".local/bin/vp" = {
    executable = true;
    text = vpWrapper;
  };

  home.file.".local/bin/ghostty" = {
    executable = true;
    text = mkManagedWrapper "${pkgs.ghostty-bin}/bin/ghostty";
  };

  home.file.".local/bin/launch-raycast" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      /usr/bin/osascript -e 'tell application id "com.raycast.macos" to activate'
    '';
  };

  home.file.".local/bin/launch-raycast-window-command" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      case "''${1:-}" in
        left-half|right-half|top-half|bottom-half|maximize-width|restore)
          /usr/bin/open -g "raycast://extensions/raycast/window-management/$1"
          ;;
        *)
          echo "usage: launch-raycast-window-command {left-half|right-half|top-half|bottom-half|maximize-width|restore}" >&2
          exit 64
          ;;
      esac
    '';
  };

  home.file.".local/bin/clone" = {
    executable = true;
    text = repositoryCommand "clone";
  };

  home.file.".local/bin/workspace" = {
    executable = true;
    text = repositoryCommand "workspace";
  };

  home.file.".local/bin/g" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.git}/bin/git "$@"
    '';
  };

  home.file.".local/bin/gm" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.git}/bin/git gm "$@"
    '';
  };

  home.file.".local/bin/gam" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.git}/bin/git gam "$@"
    '';
  };

  home.file.".zprofile".text = ''
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';
}

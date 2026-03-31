{ config, lib, machine, pkgs, username, mkShellEnvironment, ... }:
let
  homeDir = machine.homeDirectory;
  shellEnv = mkShellEnvironment {
    inherit homeDir username;
  };
  workspaceRoot = shellEnv.workspaceRoot;
  legacyWorkspaceRoot = "${homeDir}/Code";
  cloneScriptText = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    usage_text='usage:
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
      - repositories are cloned under $GHQ_ROOT or $HOME/Source'

    fail() {
      local message=$1
      local code=''${2:-64}
      printf 'clone: %s\n' "$message" >&2
      exit "$code"
    }

    print_usage() {
      printf '%s\n' "$usage_text" >&2
    }

    maybe_normalize_host() {
      case "$1" in
        github | github.com)
          printf 'github.com\n'
          ;;
        gitlab | gitlab.com)
          printf 'gitlab.com\n'
          ;;
        *)
          return 1
          ;;
      esac
    }

    parse_ssh_url() {
      local spec=$1

      if [[ $spec =~ ^git@(github\.com|gitlab\.com):(.+)$ ]]; then
        printf '%s\t%s\n' "''${BASH_REMATCH[1]}" "''${BASH_REMATCH[2]}"
        return 0
      fi

      return 1
    }

    parse_spec() {
      local spec=$1
      local host_part
      local slug_part
      local normalized_host

      if parse_ssh_url "$spec"; then
        return 0
      fi

      case "$spec" in
        http://* | https://*)
          fail "only SSH remotes are supported"
          ;;
      esac

      [[ $spec == */* ]] || return 1

      host_part=''${spec%%/*}
      slug_part=''${spec#*/}
      normalized_host=$(maybe_normalize_host "$host_part" || true)

      if [[ -z $normalized_host ]]; then
        fail "unsupported host: $host_part"
      fi

      printf '%s\t%s\n' "$normalized_host" "$slug_part"
    }

    validate_slug() {
      local cleaned=$1
      local part

      cleaned=''${cleaned#/}
      cleaned=''${cleaned%/}
      cleaned=''${cleaned%.git}

      if [[ -z $cleaned ]]; then
        fail "repository path is required"
      fi

      if [[ $cleaned != */* ]]; then
        fail "repository path must look like <owner>/<repo>"
      fi

      IFS='/' read -r -a parts <<<"$cleaned"
      for part in "''${parts[@]}"; do
        if [[ -z $part ]]; then
          fail "repository path contains an empty segment"
        fi

        if [[ $part == "." || $part == ".." ]]; then
          fail "repository path contains an invalid segment: $part"
        fi
      done

      printf '%s\n' "$cleaned"
    }

    validate_alias() {
      local alias_name=$1

      if [[ -z $alias_name ]]; then
        fail "alias must not be empty"
      fi

      if [[ $alias_name == */* ]]; then
        fail "alias must not contain '/'"
      fi

      if [[ $alias_name == "." || $alias_name == ".." ]]; then
        fail "alias must not be '.' or '..'"
      fi
    }

    command_path() {
      type -P -- "$1" 2>/dev/null || true
    }

    parse_host_and_slug() {
      local pair=$1
      IFS=$'\t' read -r PARSED_HOST PARSED_SLUG <<<"$pair"
    }

    main() {
      local alias_name=""
      local host=""
      local slug=""
      local first
      local second
      local normalized_host
      local parsed
      local root
      local repo_name
      local namespace
      local local_name
      local target
      local remote
      local git
      local -a args=()

      while [[ $# -gt 0 ]]; do
        case "$1" in
          -a | --alias)
            [[ $# -ge 2 ]] || fail "missing value for $1"
            [[ -z $alias_name ]] || fail "alias specified twice"
            alias_name=$2
            shift 2
            ;;
          -h | --help)
            print_usage
            exit 0
            ;;
          --)
            shift
            while [[ $# -gt 0 ]]; do
              args+=("$1")
              shift
            done
            ;;
          -*)
            fail "unknown option: $1"
            ;;
          *)
            args+=("$1")
            shift
            ;;
        esac
      done

      case ''${#args[@]} in
        1)
          parsed=$(parse_spec "''${args[0]}" || true)
          if [[ -z $parsed ]]; then
            print_usage
            fail "missing host or repository path"
          fi
          parse_host_and_slug "$parsed"
          host=$PARSED_HOST
          slug=$PARSED_SLUG
          ;;
        2)
          first=''${args[0]}
          second=''${args[1]}
          normalized_host=$(maybe_normalize_host "$first" || true)

          if [[ -n $normalized_host ]]; then
            host=$normalized_host
            slug=$second
          else
            [[ -z $alias_name ]] || fail "alias specified twice"
            parsed=$(parse_spec "$first" || true)
            if [[ -z $parsed ]]; then
              print_usage
              fail "missing host or repository path"
            fi
            parse_host_and_slug "$parsed"
            host=$PARSED_HOST
            slug=$PARSED_SLUG
            alias_name=$second
          fi
          ;;
        3)
          normalized_host=$(maybe_normalize_host "''${args[0]}" || true)
          [[ -n $normalized_host ]] || fail "unsupported host: ''${args[0]}"
          [[ -z $alias_name ]] || fail "alias specified twice"
          host=$normalized_host
          slug=''${args[1]}
          alias_name=''${args[2]}
          ;;
        *)
          print_usage
          fail "unexpected arguments"
          ;;
      esac

      slug=$(validate_slug "$slug")

      if [[ -n $alias_name ]]; then
        validate_alias "$alias_name"
      fi

      repo_name=''${slug##*/}
      namespace=''${slug%/*}
      local_name=$repo_name
      if [[ -n $alias_name ]]; then
        local_name="''${repo_name}--''${alias_name}"
      fi

      root=''${GHQ_ROOT:-"$HOME/Source"}
      target="''${root}/''${host}/''${namespace}/''${local_name}"
      remote="git@''${host}:''${slug}.git"

      if [[ $host != "github.com" && $host != "gitlab.com" ]]; then
        fail "only github.com and gitlab.com are supported"
      fi

      [[ ! -e $target ]] || fail "target already exists: $target"

      git=$(command_path git)
      [[ -n $git ]] || fail "git is not installed"

      mkdir -p "$(dirname "$target")"

      printf 'cloning %s\n' "$remote"
      printf '  -> %s\n' "$target"

      exec "$git" clone "$remote" "$target"
    }

    main "$@"
  '';
  raycastLauncher = "${homeDir}/.local/bin/launch-raycast";
  raycastWindowCommandLauncher = "${homeDir}/.local/bin/launch-raycast-window-command";
  hhkbVendorId = 1278;
  hhkbProductId = 33;
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
    ze = "zed";
  };
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
    ./git.nix
    ./shell.nix
    ./editor.nix
    ./devtools.nix
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
    fastfetch
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
    gotools
    rust-analyzer
    xh
    yq-go
    rustc
    rustfmt
  ];

  home.sessionVariables = shellEnv.sessionVariables;

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

  xdg.configFile."ush/config.json".text = builtins.toJSON {
    shell = {
      historySize = 1000000;
      interaction = true;
      stylishDefault = false;
    };
    aliases = commonShellAliases;
  };

  xdg.configFile."ghostty/config".text = ''
    env = XDG_CONFIG_HOME=${homeDir}/.config
    env = XDG_CACHE_HOME=${homeDir}/.cache
    env = XDG_DATA_HOME=${homeDir}/.local/share
    env = XDG_STATE_HOME=${homeDir}/.local/state
    font-family = Menlo
    font-family = "JetBrainsMono Nerd Font Mono"
    font-size = 15
    keybind = global:shift+space=toggle_quick_terminal
    macos-option-as-alt = true
    quick-terminal-animation-duration = 0
    quick-terminal-position = left
    quick-terminal-screen = main
    quick-terminal-size = 50%
    shell-integration = detect
    theme = "GitHub Dark High Contrast"
    window-padding-x = 12
    window-padding-y = 12
  '';

  xdg.configFile."karabiner/karabiner.json".text = karabinerConfig;

  xdg.configFile."nix/README.md".text = ''
    Place custom package overlays here later if you decide to package Dia or other workstation assets.
  '';

  home.file.".config/workstation/shell/terminal-env.sh".text = ''
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

  home.file.".local/bin/zed" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.zed-editor}/bin/zeditor "$@"
    '';
  };

  home.file.".local/bin/ghostty" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.ghostty-bin}/bin/ghostty "$@"
    '';
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
    text = cloneScriptText;
  };

  home.file.".zprofile".text = ''
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';
}

{ config, lib, pkgs, mkShellEnvironment, ... }:
let
  shellEnv = mkShellEnvironment {
    homeDir = config.home.homeDirectory;
    username = config.home.username;
  };
in
{
  home.packages = with pkgs; [
    atuin
    carapace
  ];

  home.activation.generateAtuinNushellInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/share/atuin"
    "${pkgs.atuin}/bin/atuin" init nu > "$HOME/.local/share/atuin/init.nu"
  '';

  programs.bash = {
    enable = true;
    initExtra = ''
      if [ -f "$HOME/.config/workstation/shell/terminal-env.sh" ]; then
        . "$HOME/.config/workstation/shell/terminal-env.sh"
      fi
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.mise = {
    enable = true;
    enableBashIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;
  };

  programs.fzf.enable = true;
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = false;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = "$directory$git_branch$line_break$character";
      right_format = "";

      character = {
        success_symbol = "[\\( ◠ ‿ ◠\\)و](bold #2aa182)";
        error_symbol = "[\\( ◠ ‿ ◠\\)و](bold red)";
        vimcmd_symbol = "[❮](bold)";
      };

      directory = {
        home_symbol = "~";
        read_only = " 󰌾";
        style = "bold";
        truncation_length = 3;
        truncation_symbol = "…/";
        format = "[ ::](fg:8)[$path]($style)[$read_only]($read_only_style)";
      };

      git_branch = {
        symbol = " ";
        style = "cyan";
        format = " [$symbol$branch]($style)";
      };

      git_status = {
        disabled = true;
      };
    };
  };

  programs.nushell = {
    enable = true;
    extraEnv = shellEnv.nuExtraEnv;
    extraConfig = ''
      if (($env.TERM? | default "") == "") {
        let fallback_term = if (($env.TMUX? | default "") != "") {
          "screen-256color"
        } else {
          "xterm-256color"
        }
        load-env {
          TERM: $fallback_term
        }
      }

      if (($env.COLORTERM? | default "") == "") {
        load-env {
          COLORTERM: "truecolor"
        }
      }

      if ("~/.local/share/atuin/init.nu" | path exists) {
        source ~/.local/share/atuin/init.nu
      }

      $env.config.show_banner = false
      $env.config.edit_mode = "emacs"
      $env.config.show_hints = true
      $env.config.history = {
        max_size: 1_000_000
        sync_on_enter: true
        file_format: sqlite
        isolation: false
      }

      let carapace_completer = {|spans: list<string>|
        let expanded_alias = (
          scope aliases
          | where name == $spans.0
          | get -o 0.expansion
        )

        let spans = if $expanded_alias != null {
          let expanded_command = ($expanded_alias | split row " " | get 0)
          $spans | skip 1 | prepend $expanded_command
        } else {
          $spans
        }

        let results = (CARAPACE_LENIENT=1 carapace $spans.0 nushell ...$spans | from json)
        if ($results | is-empty) { null } else { $results }
      }

      $env.config.completions = (
        $env.config.completions
        | merge {
            algorithm: "fuzzy"
            quick: true
            partial: true
            external: {
              enable: true
              max_results: 100
              completer: $carapace_completer
            }
          }
      )

      let fastfetch_once = ($env.HOME | path join ".local" "bin" "run-fastfetch-once")
      if $nu.is-interactive and ($fastfetch_once | path exists) {
        ^$fastfetch_once
      }

      source ~/.config/nushell/starship.nu
    '';

    shellAliases = {
      ll = "eza -lah --git";
      t = "tmux attach -t main || tmux new -s main";
    };
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    terminal = "screen-256color";
    extraConfig = ''
      set -g status-position top
      set -g renumber-windows on
      bind-key -r C-h select-pane -L
      bind-key -r C-j select-pane -D
      bind-key -r C-k select-pane -U
      bind-key -r C-l select-pane -R
    '';
  };

  programs.zoxide.enable = true;

  home.file.".local/bin/run-fastfetch-once" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      [ -t 1 ] || exit 0
      [ "''${TERM:-}" != "dumb" ] || exit 0
      [ -z "''${TMUX:-}" ] || exit 0

      if ! command -v fastfetch >/dev/null 2>&1; then
        exit 0
      fi

      state_root="$(/usr/bin/printenv XDG_STATE_HOME || true)"
      if [ -n "$state_root" ]; then
        state_dir="$state_root/workstation"
      else
        state_dir="$HOME/.local/state/workstation"
      fi
      sentinel="$state_dir/fastfetch-first-run.done"

      [ ! -e "$sentinel" ] || exit 0

      mkdir -p "$state_dir"

      if fastfetch; then
        : > "$sentinel"
      fi
    '';
  };

  home.file.".config/nushell/starship.nu".text = ''
    $env.STARSHIP_SHELL = "nu"
    $env.STARSHIP_SESSION_KEY = ($env.STARSHIP_SESSION_KEY? | default (random chars -l 16))
    $env.PROMPT_MULTILINE_INDICATOR = (
      ^${pkgs.starship}/bin/starship prompt --continuation
    )
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_COMMAND = {||
      let cmd_duration = if (($env.CMD_DURATION_MS? | default "0823") == "0823") {
        0
      } else {
        $env.CMD_DURATION_MS
      }

      (
        ^${pkgs.starship}/bin/starship prompt
          --cmd-duration $cmd_duration
          $"--status=(($env.LAST_EXIT_CODE? | default 0))"
          --terminal-width ((term size).columns)
      )
    }
    $env.PROMPT_COMMAND_RIGHT = {||
      let cmd_duration = if (($env.CMD_DURATION_MS? | default "0823") == "0823") {
        0
      } else {
        $env.CMD_DURATION_MS
      }

      (
        ^${pkgs.starship}/bin/starship prompt
          --right
          --cmd-duration $cmd_duration
          $"--status=(($env.LAST_EXIT_CODE? | default 0))"
          --terminal-width ((term size).columns)
      )
    }
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    dotDir = config.home.homeDirectory;
    syntaxHighlighting.enable = true;
    initContent = ''
      if [ -f "$HOME/.config/workstation/shell/terminal-env.sh" ]; then
        . "$HOME/.config/workstation/shell/terminal-env.sh"
      fi

      if [ -x "$HOME/.local/bin/run-fastfetch-once" ]; then
        "$HOME/.local/bin/run-fastfetch-once"
      fi
    '';
  };
}

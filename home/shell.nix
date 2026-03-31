{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    atuin
    carapace
    ush
  ];

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

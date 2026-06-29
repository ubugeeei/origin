let
  module = _args: {
    programs = {
      bat = {
        enable = true;
      };
      eza = {
        enable = true;
      };
    };
    home = {
      file = builtins.listToAttrs [ {
        name = ".config/nvim/README.md";
        value = {
          text = "Neovim is intentionally the lightweight secondary editor in this setup.
          ";
        };
      } {
        name = ".config/workstation/manual-apps.md";
        value = {
          text = "Manual follow-up items:

          - Dia: this machine already has the app and sets it as the default browser, but the install source is still outside the flake.
          - azooKey: packaged already, but the macOS input source still needs a logout/login plus enablement in Keyboard settings.
          - Karabiner-Elements: open it once and approve macOS permissions so the HHKB profile and launcher hotkeys can work.
          - Fonts: drop additional Nova variants into assets/fonts if you want them packaged on the next apply.
          ";
        };
      } ];
    };
  };
in module
{ pkgs, ... }:
{
  programs.bat.enable = true;
  programs.eza.enable = true;

  home.file.".config/nvim/README.md".text = ''
    Neovim is intentionally the lightweight secondary editor in this setup.
  '';

  home.file.".config/workstation/manual-apps.md".text = ''
    Manual follow-up items:

    - Dia: this machine already has the app and sets it as the default browser, but the install source is still outside the flake.
    - azooKey: packaged already, but the macOS input source still needs a logout/login plus enablement in Keyboard settings.
    - Karabiner-Elements: open it once and approve macOS permissions so the HHKB profile and launcher hotkeys can work.
    - Fonts: drop additional Nova variants into assets/fonts if you want them packaged on the next apply.
  '';
}

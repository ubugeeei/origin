{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      lua-language-server
      nil
      stylua
      tree-sitter
    ];
    initLua = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.smartindent = true

      vim.filetype.add({
        extension = { tnix = "tnix" },
        pattern = { [".*%.d%.tnix"] = "tnix" },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tnix",
        callback = function(args)
          -- Only attach when tnix-lsp is already available on PATH.
          if vim.fn.executable("tnix-lsp") ~= 1 then
            return
          end

          vim.lsp.start({
            name = "tnix-lsp",
            cmd = { "tnix-lsp" },
            root_dir = vim.fs.root(args.buf, { "tnix.config.tnix", "flake.nix", ".git" }) or vim.loop.cwd(),
          })
        end,
      })
    '';
  };

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "tnix"
      "toml"
      "make"
      "dockerfile"
      "git-firefly"
    ];
    userSettings = {
      auto_update = false;
      base_keymap = "VSCode";
      buffer_font_family = "Nova";
      buffer_font_fallbacks = [ "JetBrainsMono Nerd Font Mono" ];
      features = {
        edit_prediction_provider = "copilot";
      };
      file_types = {
        tnix = [ "*.d.tnix" ];
      };
      format_on_save = "on";
      relative_line_numbers = true;
      terminal = {
        font_family = "JetBrainsMono Nerd Font Mono";
        shell = {
          program = "${pkgs.ush}/bin/ush";
        };
      };
      theme = {
        mode = "system";
      };
      ui_font_family = "Nova";
      ui_font_fallbacks = [ "JetBrainsMono Nerd Font Mono" ];
      ui_font_size = 16;
      buffer_font_size = 15;
    };
  };
}

{ lib, machine, ... }:
let
  identitySettings =
    (lib.optionalAttrs (machine.git.userName != null) {
      user.name = machine.git.userName;
    })
    // (lib.optionalAttrs (machine.git.userEmail != null) {
      user.email = machine.git.userEmail;
    })
    // (lib.optionalAttrs (machine.git.githubUser != null) {
      github.user = machine.git.githubUser;
    });
in
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
    };
  };

  programs.git = {
    enable = true;
    settings = identitySettings // {
      alias = {
        ap = "add -p";
        ds = "diff --staged";
        ga = "add";
        gaa = "add --all";
        gam = "commit --amend";
        gb = "branch";
        gbda = "!f() { current=$(git branch --show-current); git for-each-ref --format='%(refname:short)' refs/heads | while IFS= read -r branch; do [ \"$branch\" = \"$current\" ] && continue; git branch -D \"$branch\"; done; }; f";
        gco = "checkout";
        gf = "fetch";
        gm = "commit -m";
        grm = "rm -rf --cached";
        gs = "status -sb";
        gsw = "switch";
        last = "log -1 HEAD --stat";
        lg = "log --graph --decorate --oneline --all";
        rb = "rebase";
        ri = "rebase -i";
        unstage = "restore --staged";
      };

      core = {
        editor = "nvim";
      };
      sequence.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      url."git@github.com:".insteadOf = [
        "https://github.com/"
        "git://github.com/"
      ];

      url."git@gitlab.com:".insteadOf = [
        "https://gitlab.com/"
        "git://gitlab.com/"
      ];
    };

    ignores = [
      ".DS_Store"
      ".direnv"
      ".envrc.local"
    ];
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "zed";
      prompt = "enabled";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
      };
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
      };
    };
  };
}

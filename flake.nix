{
  description = "Portable nix-darwin workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      machine = import ./machine/default.nix;
      system = machine.system;
      username = machine.username;
      defaultWorkspaceRoot = machine.workspaceRoot;
      mkShellEnvironment =
        {
          homeDir,
          username,
          workspaceRoot ? defaultWorkspaceRoot,
        }:
        let
          cargoHome = "${homeDir}/.cargo";
          goPath = "${homeDir}/go";
          goBin = "${goPath}/bin";
          bunInstall = "${homeDir}/.bun";
          bunBin = "${bunInstall}/bin";
          miseShims = "${homeDir}/.local/share/mise/shims";
          pnpmHome = "${homeDir}/Library/pnpm";
          vitePlusHome = "${homeDir}/.vite-plus";
          managedPathEntries = [
            "${vitePlusHome}/bin"
            "${homeDir}/.local/bin"
            miseShims
            "${cargoHome}/bin"
            goBin
            bunBin
            pnpmHome
            "${homeDir}/.local/state/nix/profiles/home-manager/home-path/bin"
            "${homeDir}/.nix-profile/bin"
            "/nix/var/nix/profiles/default/bin"
            "/etc/profiles/per-user/${username}/bin"
            "/run/current-system/sw/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
          sessionVariables = {
            BROWSER = "open";
            BUN_INSTALL = bunInstall;
            CARGO_HOME = cargoHome;
            EDITOR = "zed";
            GHQ_ROOT = workspaceRoot;
            GOBIN = goBin;
            GOPATH = goPath;
            PNPM_HOME = pnpmHome;
            STARSHIP_CONFIG = "${homeDir}/.config/starship.toml";
            VISUAL = "zed";
            VITE_PLUS_HOME = vitePlusHome;
            XDG_CACHE_HOME = "${homeDir}/.cache";
            XDG_CONFIG_HOME = "${homeDir}/.config";
            XDG_DATA_HOME = "${homeDir}/.local/share";
            XDG_STATE_HOME = "${homeDir}/.local/state";
          };
          sessionVariableNames = builtins.attrNames sessionVariables;
          nuEnvAssignments = builtins.concatStringsSep "\n" (
            map (name: "$env.${name} = \"${sessionVariables.${name}}\"") sessionVariableNames
          );
          loginShell = "/run/current-system/sw/bin/nu";
        in
        {
          inherit loginShell managedPathEntries sessionVariables workspaceRoot;

          launchdEnvVariables = sessionVariables // {
            PATH = builtins.concatStringsSep ":" managedPathEntries;
            SHELL = loginShell;
          };

          nuExtraEnv = ''
            let managed_path_entries = ('${builtins.toJSON managedPathEntries}' | from json)
            let current_path = ($env.PATH? | default [])

            $env.PATH = (
              $managed_path_entries
              | append (
                  $current_path
                  | where {|entry| not ($managed_path_entries | any {|candidate| $candidate == $entry }) }
                )
            )

            ${nuEnvAssignments}
          '';
        };
      homeConfigurationName = "${username}@${machine.networking.localHostName}";
      overlays = [
        (final: prev: {
          azookey-mac = prev.callPackage ./pkgs/azookey-mac.nix { };
          chrome-webapp-bundle = prev.callPackage ./pkgs/chrome-webapp-bundle.nix { };
          moonbit = prev.callPackage ./pkgs/moonbit.nix { };
          nova-font = prev.callPackage ./pkgs/nova-font.nix { };
          vite-plus = prev.callPackage ./pkgs/vite-plus.nix { };
          gmail-app = final.chrome-webapp-bundle {
            appName = "Gmail";
            bundleId = "${machine.appNamespace}.gmail";
            url = "https://mail.google.com/";
          };
          google-calendar-app = final.chrome-webapp-bundle {
            appName = "Google Calendar";
            bundleId = "${machine.appNamespace}.google-calendar";
            url = "https://calendar.google.com/";
          };
          twitter-app = final.chrome-webapp-bundle {
            appName = "Twitter";
            bundleId = "${machine.appNamespace}.twitter";
            url = "https://x.com/";
          };
          microsoft-edge-mac = prev.callPackage ./pkgs/microsoft-edge-mac.nix { };

          gmail-open = prev.writeShellApplication {
            name = "gmail-open";
            text = ''open "https://mail.google.com/"'';
          };

          gcal-open = prev.writeShellApplication {
            name = "gcal-open";
            text = ''open "https://calendar.google.com/"'';
          };

          twitter-open = prev.writeShellApplication {
            name = "twitter-open";
            text = ''open "https://x.com/"'';
          };
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {
        inherit (pkgs) moonbit;
      };

      homeConfigurations.${homeConfigurationName} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit machine username mkShellEnvironment;
        };
        modules = [
          ./home/default.nix
        ];
      };

      darwinConfigurations.workstation = nix-darwin.lib.darwinSystem {
        inherit system pkgs;
        specialArgs = {
          inherit inputs machine username mkShellEnvironment;
        };
        modules = [
          ./modules/darwin/core.nix
          ./modules/darwin/desktop-apps.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.backupFileExtension = "before-origin";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit machine username mkShellEnvironment;
            };
            home-manager.users.${username} = import ./home/default.nix;
          }
        ];
      };
    };
}

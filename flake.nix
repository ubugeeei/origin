{
  description = "Portable nix-darwin workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ush.url = "github:ubugeeei/ush";
    ush.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      machine = import ./generated/machine/default.nix;
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
          moonHome = "${homeDir}/.moon";
          moonBin = "${moonHome}/bin";
          miseShims = "${homeDir}/.local/share/mise/shims";
          pnpmHome = "${homeDir}/Library/pnpm";
          vitePlusHome = "${homeDir}/.vite-plus";
          managedPathEntries = [
            "${vitePlusHome}/bin"
            "${homeDir}/.local/bin"
            moonBin
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
            MOON_HOME = moonHome;
            PNPM_HOME = pnpmHome;
            STARSHIP_CONFIG = "${homeDir}/.config/starship.toml";
            VISUAL = "zed";
            VITE_PLUS_HOME = vitePlusHome;
            XDG_CACHE_HOME = "${homeDir}/.cache";
            XDG_CONFIG_HOME = "${homeDir}/.config";
            XDG_DATA_HOME = "${homeDir}/.local/share";
            XDG_STATE_HOME = "${homeDir}/.local/state";
          };
          loginShell = "/run/current-system/sw/bin/ush";
        in
        {
          inherit loginShell managedPathEntries sessionVariables workspaceRoot;

          launchdEnvVariables = sessionVariables // {
            PATH = builtins.concatStringsSep ":" managedPathEntries;
            SHELL = loginShell;
          };
        };
      homeConfigurationName = "${username}@${machine.networking.localHostName}";
      overlays = [
        (final: prev: {
          azookey-mac = prev.callPackage ({
            stdenvNoCC,
            fetchurl,
            xar,
            cpio,
            gzip,
            lib,
          }:
            import ./generated/pkgs/azookey-mac.nix {
              inherit stdenvNoCC fetchurl xar cpio gzip lib;
            }) { };
          chrome-webapp-bundle = prev.callPackage ({
            stdenvNoCC,
            lib,
          }:
            import ./generated/pkgs/chrome-webapp-bundle.nix {
              inherit stdenvNoCC lib;
            }) { };
          moonbit = prev.callPackage ({
            stdenvNoCC,
            fetchurl,
            lib,
          }:
            import ./generated/pkgs/moonbit.nix {
              inherit stdenvNoCC fetchurl lib;
            }) { };
          nova-font = prev.callPackage ({
            lib,
            stdenvNoCC,
          }:
            import ./generated/pkgs/nova-font.nix {
              inherit lib stdenvNoCC;
              fontSrc = ./assets/fonts;
            }) { };
          ush = inputs.ush.packages.${system}.default.overrideAttrs (_: {
            doCheck = false;
          });
          vite-plus = prev.callPackage ({
            stdenvNoCC,
            fetchurl,
            lib,
          }:
            import ./generated/pkgs/vite-plus.nix {
              inherit stdenvNoCC fetchurl lib;
            }) { };
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
          microsoft-edge-mac = prev.callPackage ({
            stdenvNoCC,
            fetchurl,
            xar,
            cpio,
            gzip,
            lib,
          }:
            import ./generated/pkgs/microsoft-edge-mac.nix {
              inherit stdenvNoCC fetchurl xar cpio gzip lib;
            }) { };

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
        inherit (pkgs) ush;
      };

      homeConfigurations.${homeConfigurationName} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit machine username mkShellEnvironment;
        };
        modules = [
          ./src/nix/home/default.nix
        ];
      };

      darwinConfigurations.workstation = nix-darwin.lib.darwinSystem {
        inherit system pkgs;
        specialArgs = {
          inherit inputs machine username mkShellEnvironment;
        };
        modules = [
          ({ config, machine, pkgs, username, mkShellEnvironment, ... }:
            import ./generated/modules/darwin/core.nix {
              inherit config machine pkgs username mkShellEnvironment;
            })
          ({ config, pkgs, ... }:
            import ./generated/modules/darwin/desktop-apps.nix {
              inherit config pkgs;
            })
          home-manager.darwinModules.home-manager
          {
            home-manager.backupCommand = pkgs.writeShellScript "home-manager-backup-existing" ''
              set -eu

              target="$1"
              stamp="$(/bin/date +%Y%m%d-%H%M%S)"
              backup="$target.before-origin.$stamp"
              index=0

              while [ -e "$backup" ]; do
                index=$((index + 1))
                backup="$target.before-origin.$stamp.$index"
              done

              mv "$target" "$backup"
            '';
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit machine username mkShellEnvironment;
            };
            home-manager.users.${username} = import ./src/nix/home/default.nix;
          }
        ];
      };
    };
}

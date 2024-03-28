{
  description = "Your trusty omnibox search.";

  # nixConfig = {
  #   extra-substituters = [ "https://friedow.cachix.org" ];
  #   extra-trusted-public-keys =
  #     [ "friedow.cachix.org-1:JDEaYMqNgGu+bVPOca7Zu4Cp8QDMkvQpArKuwPKa29A=" ];
  # };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    treefmt-nix.url = "github:numtide/treefmt-nix/";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, treefmt-nix, home-manager, ... }:
    let
      inherit (nixpkgs) lib;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.fileFilter (x:
          x.hasExt "ttf" || x.hasExt "rs" || x.hasExt "toml" || x.hasExt "lock")
          ./.;
      };

      inherit ((lib.importTOML ./Cargo.toml).workspace.package) version;

      GIT_DATE = "${builtins.substring 0 4 self.lastModifiedDate}-${
          builtins.substring 4 2 self.lastModifiedDate
        }-${builtins.substring 6 2 self.lastModifiedDate}";
      GIT_REV = self.shortRev or "Not committed yet.";


      treefmt = (treefmt-nix.lib.evalModule pkgs ./formatter.nix).config.build;
      libPath = lib.makeLibraryPath [
        pkgs.wayland
        pkgs.libxkbcommon
        pkgs.vulkan-loader
        pkgs.libGL
      ];
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {

        inputsFrom = [ self.packages.x86_64-linux.default ];

        packages = [ pkgs.rustfmt pkgs.rust-analyzer treefmt.wrapper ];
        env = {
          inherit GIT_DATE GIT_REV;
          LD_LIBRARY_PATH = libPath;
        };
      };

      packages.x86_64-linux = {
        default = pkgs.rustPlatform.buildRustPackage {

          pname = "centerpiece";
          inherit src version;

          nativeBuildInputs = [ pkgs.pkg-config ];

          buildInputs = [ pkgs.dbus ];

          env = { inherit GIT_REV GIT_DATE; };

          cargoLock.lockFile = ./Cargo.lock;

          strictDeps = true;

          postFixup = lib.optional pkgs.stdenv.isLinux ''
            rpath=$(patchelf --print-rpath $out/bin/centerpiece)
            patchelf --set-rpath "$rpath:${libPath}" $out/bin/centerpiece
          '';

          meta = {
            description = "Your trusty omnibox search.";
            homepage = "https://github.com/friedow/centerpiece";
            license = lib.licenses.mit;
            mainProgram = "centerpiece";
          };
        };
        index-git-repositories = pkgs.rustPlatform.buildRustPackage {
          pname = "index-git-repositories";
          inherit src version;

          cargoExtraArgs = "-p centerpiece";
          meta.mainProgram = "centerpiece";
        };
      };
      checks.x86_64-linux = {
        inherit (self.outputs.packages.x86_64-linux)
          default index-git-repositories;
        shell = self.outputs.devShells.x86_64-linux.default;
        treefmt = treefmt.check self;
        hmModule = (nixpkgs.lib.nixosSystem {
          modules = [
            home-manager.nixosModules.home-manager
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              home-manager.users.alice = {
                imports = [ self.outputs.hmModules.x86_64-linux.default ];
                programs.centerpiece = {
                  enable = true;
                  config.plugin.git_repositories.commands = [ [ "alacritty" ] ];
                  services.index-git-repositories = {
                    enable = true;
                    interval = "3hours";
                  };
                };
                home.stateVersion = "23.11";
              };
              users.users.alice = {
                isNormalUser = true;
                uid = 1000;
                home = "/home/alice";
              };
            }
          ];
        }).config.system.build.vm;
      };
      homeManagerModules.default = import ./home-manager-module.nix self;

      formatter.x86_64-linux = treefmt.wrapper;
    };
}

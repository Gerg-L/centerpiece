{
  description = "Your trusty omnibox search.";

  nixConfig = {
    extra-substituters = [ "https://friedow.cachix.org" ];
    extra-trusted-public-keys =
      [ "friedow.cachix.org-1:JDEaYMqNgGu+bVPOca7Zu4Cp8QDMkvQpArKuwPKa29A=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, treefmt-nix, home-manager, ... }:
    let
      inherit (nixpkgs) lib;

      inherit ((lib.importTOML ./Cargo.toml).workspace.package) version;

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./client
          ./services/index-git-repositories
          ./Cargo.lock
          ./Cargo.toml
        ];
      };

      GIT_DATE = "${builtins.substring 0 4 self.lastModifiedDate}-${
          builtins.substring 4 2 self.lastModifiedDate
        }-${builtins.substring 6 2 self.lastModifiedDate}";
      GIT_REV = self.shortRev or "Not committed yet.";

      # Incorrect scoping
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

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

        default = self.packages.x86_64-linux.centerpiece;

        centerpiece = pkgs.rustPlatform.buildRustPackage {

          pname = "centerpiece";
          inherit version src;

          nativeBuildInputs = [ pkgs.pkg-config ];

          buildInputs = [ pkgs.dbus ];

          env = { inherit GIT_REV GIT_DATE; };

          cargoLock.lockFile = ./Cargo.lock;

          strictDeps = true;

          postFixup = lib.optional pkgs.stdenv.isLinux ''
            rpath=$(patchelf --print-rpath $out/bin/centerpiece)
            patchelf --set-rpath "$rpath:${libPath}" $out/bin/centerpiece
          '';

          cargoBuildFlags = [ "--package centerpiece" ];

          meta = {
            description = "Your trusty omnibox search.";
            homepage = "https://github.com/friedow/centerpiece";
            license = lib.licenses.mit;
            mainProgram = "centerpiece";
          };
        };

        index-git-repositories = pkgs.rustPlatform.buildRustPackage {
          pname = "index-git-repositories";

          inherit version src;

          nativeBuildInputs = [ pkgs.pkg-config ];

          buildInputs = [ pkgs.dbus ];

          env = { inherit GIT_REV GIT_DATE; };

          cargoLock.lockFile = ./Cargo.lock;

          strictDeps = true;

          cargoBuildFlags = [ "--package index-git-repositories" ];

          meta.mainProgram = "index-git-repositories";
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

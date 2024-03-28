self:
{ lib, config, pkgs, ... }:
let
  cfg = config.programs.centerpiece;

  inherit (pkgs.stdenv.hostPlatform) system;

  defaultTrueOption = x: (lib.mkEnableOption x) // { default = true; };

  pluginOption = defaultTrueOption "/ disable the plugin";
in {
  options.programs.centerpiece = {
    enable = lib.mkEnableOption "Centerpiece";

    config.plugin = {
      applications.enable = pluginOption;

      brave_bookmarks.enable = pluginOption;

      brave_history.enable = pluginOption;

      brave_progressive_web_apps.enable = pluginOption;

      clock.enable = pluginOption;

      git_repositories = {
        enable = pluginOption;
        commands = lib.mkOption {
          default = [
            [ "alacritty" "--command" "nvim" "$GIT_DIRECTORY" ]
            [ "alacritty" "--working-directory" "$GIT_DIRECTORY" ]
          ];
          type = lib.types.listOf (lib.types.listOf lib.types.str);
          description = ''
            The commands to launch when an entry is selected.
            Use the $GIT_DIRECTORY variable to pass in the selected directory.
            Use the $GIT_DIRECTORY_NAME variable to pass in the selected directory name.
          '';
          example = [
            [ "code" "--new-window" "$GIT_DIRECTORY" ]
            [ "alacritty" "--command" "lazygit" "--path" "$GIT_DIRECTORY" ]
            [ "alacritty" "--working-directory" "$GIT_DIRECTORY" ]
          ];
        };
      };

      resource_monitor_battery.enable = pluginOption;

      resource_monitor_cpu.enable = pluginOption;

      resource_monitor_disks.enable = pluginOption;

      resource_monitor_memory.enable = pluginOption;

      sway_windows.enable = pluginOption;

      system.enable = pluginOption;

      wifi.enable = pluginOption;
    };

    services.index-git-repositories = {
      enable =
        defaultTrueOption " / disable the git repositories indexer service";

      interval = lib.mkOption {
        default = "5min";
        type = lib.types.str;
        example = "hourly";
        description = ''
          Frequency of index creation.

          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.enable {
      xdg.configFile."centerpiece/config.yml".text =
        lib.generators.toYAML { } cfg.config;
      home.packages = [ self.packages.${system}.centerpiece ];
    })

    (lib.mkIf cfg.services.index-git-repositories.enable {
      systemd.user = {
        services.index-git-repositories-service = {
          Unit = {
            Description = "Centerpiece - your trusty omnibox search";
            Documentation = "https://github.com/friedow/centerpiece";
          };

          Service = {
            ExecStart =
              lib.getExe self.packages.${system}.index-git-repositories;
            Type = "oneshot";
          };
        };
        timers.index-git-repositories-timer = {
          Unit.Description = "Activate the git repository indexer";
          Install.WantedBy = [ "timers.target" ];

          Timer = {
            OnUnitActiveSec = cfg.services.index-git-repositories.interval;
            OnBootSec = "0min";
            Persistent = true;
            Unit = "git-index-name-service.service";
          };
        };
      };
    })
  ];

  _file = ./home-manager-module.nix;
}

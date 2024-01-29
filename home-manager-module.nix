{ index-git-repositories, centerpiece }:
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.centerpiece;
  git-index-name = "index-git-repositories";
in
{
  options.programs.centerpiece = {
    enable = lib.mkEnableOption (lib.mdDoc "Centerpiece");
    services.index-git-repositories = {
      enable = lib.mkEnableOption (lib.mdDoc "enable timer");
      interval = lib.mkOption {
        default = "5min";
        type = lib.types.str;
        example = "hourly";
        description = lib.mdDoc ''
          Frequency of index creation.

          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { home.packages = [ centerpiece ]; })

    (lib.mkIf cfg.services.index-git-repositories.enable {
      systemd.user = {
        services = {
          index-git-repositories-service = {
            Unit = {
              Description = "Centerpiece - your trusty omnibox search";
              Documentation = "https://github.com/friedow/centerpiece";
            };

            Service = {
              ExecStart = "${pkgs.writeShellScript "${git-index-name}-service-ExecStart" ''
                exec ${lib.getExe index-git-repositories}
              ''}";
              Type = "oneshot";
            };
          };
        };
        timers = {
          index-git-repositories-timer = {
            Unit = {
              Description = "Activate the git repository indexer";
            };
            Install = {
              WantedBy = [ "timers.target" ];
            };
            Timer = {
              OnUnitActiveSec = cfg.services.index-git-repositories.interval;
              OnBootSec = "0min";
              Persistent = true;
              Unit = "${git-index-name}-service.service";
            };
          };
        };
      };
    })
  ];
}
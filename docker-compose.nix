{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dockerComposeServices = {
    composeDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "List of directories with docker-compose.yml files.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run the docker-compose services as. Defaults to 'root'.";
    };
  };

  config = lib.mkIf (config.dockerComposeServices.composeDirs != []) {
    # --- Module Dependencies ---
    # This module requires the Docker daemon to be running.
    virtualisation.docker.enable = true;

    # Make docker-compose available in the system path for manual debugging (e.g., `docker-compose logs`).
    # The module itself uses the full package path, so this is for user convenience.
    environment.systemPackages = [pkgs.docker-compose];

    # --- Service Generation ---
    systemd.services = let
      # For each user-provided directory, create a stable name and a clean copy in the Nix store.
      copiedDirs =
        map (dir: {
          # Use the basename of the directory for a stable, human-readable name.
          name = lib.strings.sanitizeDerivationName (baseNameOf (toString dir));
          # The path to the directory containing the compose file.
          # Nix will automatically handle copying it to the store.
          copiedPath = dir;
        })
        config.dockerComposeServices.composeDirs;
    in
      lib.listToAttrs (map (entry: {
          name = "compose-${entry.name}";
          value = {
            description = "Docker Compose Application: ${entry.name}";
            after = ["docker.service" "network.target"];
            wants = ["docker.service"];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = config.dockerComposeServices.user; # User can be configured.

              # Set the working directory to the compose files in the Nix store.
              WorkingDirectory = "${entry.copiedPath}";

              # Command to run when the service starts.
              # The -p flag provides a stable project name, which is critical for rebuilds.
              ExecStart = "${pkgs.docker-compose}/bin/docker-compose -p ${entry.name} up -d --remove-orphans";

              # Command to run when the service stops (e.g., during a nixos-rebuild).
              ExecStop = "${pkgs.docker-compose}/bin/docker-compose -p ${entry.name} down";
            };

            # This ensures that if the service definition changes, systemd stops the old
            # unit and starts the new one.
            restartIfChanged = true;
            # Start the service on boot.
            wantedBy = ["multi-user.target"];
          };
        })
        copiedDirs);
  };
}

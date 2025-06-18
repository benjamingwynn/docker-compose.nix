# NixOS Docker Compose Module

A simple and robust NixOS module to declaratively manage Docker Compose projects.

This module creates systemd services that gracefully handle `nixos-rebuild switch` by using stable project names and properly managing the `up` and `down` lifecycle.

## Usage

In your system's `flake.nix`, add this repository as an input:

```nix
# your-system/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add this flake as an input
    docker-compose-services.url = "github:<your-username>/<your-repo-name>";
  };

  outputs = { self, nixpkgs, docker-compose-services }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import the module here
        docker-compose-services.nixosModules.default

        # Your main configuration file
        ./configuration.nix
      ];
    };
  };
}
```

Then, in your `configuration.nix`, use the `dockerComposeServices.composeDirs` option:

```nix
# your-system/configuration.nix
{ config, pkgs, ... }:

{
  # ... your other system settings

  # Define the directories containing your docker-compose.yml or compose.yml files.
  # The path should be relative to this file or an absolute path.
  dockerComposeServices.composeDirs = [
    ./my-app-1
    ./my-app-2
    # /path/to/another/project
  ];
}
```

### User Configuration

By default, the systemd services that manage your Docker Compose projects run as root. You can change this by setting the `dockerComposeServices.user` option.

## How It Works

For each directory provided, the module creates a systemd service with the following behavior:

- **`ExecStart`**: Runs `docker compose -p <dir-name> up -d --remove-orphans`.
- **`ExecStop`**: Runs `docker compose -p <dir-name> down`.
- **Stable Project Name**: Uses the `-p` flag with the directory's base name to ensure containers can be found and managed correctly across rebuilds.
- **Graceful Rebuilds**: When you run `nixos-rebuild switch`, systemd stops the old service (running `down`) before starting the new one (running `up`).

## Comparison with `compose2nix`

While [`compose2nix`](https://github.com/aksiksi/compose2nix) (and similar tools like `nix-docker-compose` or `podman-compose-to-nix`) aim to convert your `docker-compose.yml` (or `compose.yml`) files into Nix derivations for building OCI images and managing containers, this module offers a different approach. This module focuses on declaratively managing the lifecycle of your Docker Compose projects as systemd services.

It achieves this by directly invoking the `docker compose` binary. In contrast, `compose2nix` translates your compose file into Nix derivations, allowing Nix to build OCI images and define container configurations within the Nix store.

A key benefit of this module is its simplicity and integration with existing workflows. It minimizes complexity and avoids "Nix lock-in" by not converting your `docker-compose.yml` files to a new format.

This makes it ideal if you prefer to keep your compose files as they are and simply need a robust NixOS-native way to manage their startup, shutdown, and graceful restarts via systemd.

Unlike compose2nix, this module does not build Docker images within the Nix store. It assumes your images are either pulled from a remote registry or built through other external means (for example, using `pkgs.dockerTools.buildImage` as a separate Nix derivation).

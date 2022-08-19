# podman.nix
#
# Podman configuration

{ config, pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    buildah
    podman-compose
    shadow
    skopeo
  ];

  virtualisation = {
    containers = {
      enable = true;

      registries.search = [ "docker.io" "quay.io" "ghcr.io" ];
    };

    podman = {
      enable = true;

      dockerCompat = !config.virtualisation.docker.enable;
      dockerSocket.enable = !config.virtualisation.docker.enable;
    };
  };
}

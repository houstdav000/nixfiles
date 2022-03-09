{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    lutris

    # Emulation
    flips
    retroarchFull

    # itch.io
    itch

    # Steam
    steam
    winetricks
    wine-wayland
    protontricks

    # Other games
    minecraft
  ];
}

_: {
  # # Enable home-manager
  # programs.home-manager.enable = true;

  imports = [
    ./nix
    # ./tui/bat.nix
    # ./tui/exa.nix
    ./tui/file.nix
    ./tui/fuse.nix
    ./tui/git.nix
    ./tui/gnupg.nix
    ./tui/htop.nix
    ./tui/less.nix
    ./tui/man.nix
    ./tui/neofetch.nix
    ./tui/neovim.nix
    # ./tui/passwords.nix
    # ./tui/shell.nix
    ./tui/ssh.nix
    # ./tui/tmux.nix
  ];

  # home.packages = with pkgs; [
  #   curlie
  #   dogdns
  #   gping
  #   procs
  #   traceroute
  # ];

  # home.sessionVariables."PAGER" = "less";

  # home.shellAliases = {
  #   "h" = "history";
  #   "pg" = "pgrep";

  #   # Editor aliases
  #   "v" = config.home.sessionVariables.EDITOR;

  #   # Make things human-readable
  #   "dd" = "dd status=progress";
  #   "df" = "df -Th";
  #   "du" = "du -h";
  #   "free" = "free -h";
  #   "pkill" = "pkill -e";
  # };

  # programs.zoxide.enable = true;

  # xdg = {
  #   enable = true;
  #   cacheHome = "${config.home.homeDirectory}/.cache";
  #   configHome = "${config.home.homeDirectory}/.config";
  #   dataHome = "${config.home.homeDirectory}/.local/share";
  #   stateHome = "${config.home.homeDirectory}/.local/state";

  #   userDirs = {
  #     enable = true;

  #     createDirectories = true;

  #     desktop = "${config.home.homeDirectory}";
  #     documents = "${config.home.homeDirectory}/docs";
  #     download = "${config.home.homeDirectory}/tmp";
  #     music = "${config.home.homeDirectory}/music";
  #     pictures = "${config.home.homeDirectory}/pics";
  #     publicShare = "${config.home.homeDirectory}/public";
  #     templates = "${config.home.homeDirectory}/.templates";
  #     videos = "${config.home.homeDirectory}/videos";

  #     extraConfig.XDG_SECRETS_DIR = "${config.home.homeDirectory}/.secrets";
  #   };
  # };

  # home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];
}

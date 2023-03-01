{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sys.shell;

  posixGitFunctions = ''
    function gcmsgp() {
      git commit -m $@ && git push
    }

    function gcmsgpf() {
      git commit -m $@ && git push --force-with-lease
    }

    function gcmsgpf!() {
      git commit -m $@ && git push --force
    }
  '';
in
{
  options.sys.shell = {
    enable = mkEnableOption "Enable shell management" // { default = true; };

    pager = mkOption {
      type = with types; nullOr str;
      default = lib.getExe pkgs.less;

      description = ''
        CLI pager to use for the user. This gets set to the PAGER env
        variable.
      '';
    };

    editor = mkOption {
      type = with types; nullOr str;
      default = lib.getExe pkgs.neovim;

      description = ''
        CLI editor to use for the user. This gets set to the EDITOR env
        variable.
      '';
    };

    viewer = mkOption {
      type = with types; nullOr str;
      default = "${lib.getExe pkgs.neovim} -R";

      description = ''
        CLI file viewer to use for the user. This gets set to the VISUAL env
        variable.
      '';
    };

    aliases = mkOption {
      type = with types; attrsOf str;

      default = {
        "h" = "history";
        "pg" = "pgrep";
        "cp" = "cp -r";
        "rm" = "rm -r";

        # Editor aliases
        "v" = config.home.sessionVariables.EDITOR or "nano";

        # Make things human-readable
        "dd" = "dd status=progress";
        "df" = "df -Th";
        "du" = "du -h";
        "free" = "free -h";
        "pkill" = "pkill -e";

        # VI Keys pls
        "info" = "info --vi-keys";
      };

      description = ''
        Aliases to add for the shell.
      '';
    };

    historyIgnore = mkOption {
      type = with types; listOf str;

      default = [
        "cd *"
        "exit"
        "export *"
        "kill *"
        "pkill"
        "pushd *"
        "popd"
        "rm *"
        "z *"
      ];

      description = ''
        Shell patterns to exclude from the history. Supported in Bash and Zsh.
      '';
    };

    manageBashConfig = mkEnableOption "Enable default bash config" // { default = true; };
    manageBatConfig = mkEnableOption "Enable default bat config" // { default = true; };
    manageExaConfig = mkEnableOption "Enable default exa config" // { default = true; };
    manageLessConfig = mkEnableOption "Enable default less config" // { default = true; };
    manageTmuxConfig = mkEnableOption "Enable deafult tmux config" // { default = true; };
    manageStarshipConfig = mkEnableOption "Enable default starship config" // { default = true; };
    manageZshConfig = mkEnableOption "Enable default zsh config" // { default = true; };

    zoxide = mkEnableOption "Enable zoxide" // { default = true; };
    z-lua = mkEnableOption "Enable z-lua";
    autojump = mkEnableOption "Enable autojump";

    fcp = mkEnableOption "Enable replacing cp with fcp";

    extraShells = mkOption {
      type = with types; nullOr (listOf package);

      default = with pkgs; [
        elvish
        powershell
      ];
    };
  };


  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = cfg.extraShells;
      home.shellAliases = cfg.aliases;

      home.sessionVariables = mkDefault {
        "PAGER" = cfg.pager;
        "EDITOR" = cfg.editor;
        "VISUAL" = cfg.viewer;
      };

      programs.autojump.enable = cfg.autojump;
      programs.z-lua.enable = cfg.z-lua;
    }

    (mkIf config.sys.git.enable {
      home.shellAliases = {
        "gi" = "git ignore";

        # Additional git aliases
        "gcmsg" = "git commit --signoff -m";
        "gcmsga" = "git commit --signoff --all -m";
      };
    })

    (mkIf cfg.manageBashConfig {
      programs.bash = {
        inherit (cfg) historyIgnore;

        enable = true;

        historyFile = "${config.xdg.dataHome or "$XDG_DATA_HOME"}/bash/bash_history";
        historyControl = [ "ignoredups" "ignorespace" ];

        initExtra = mkIf config.sys.git.enable posixGitFunctions;
      };
    })

    (mkIf cfg.manageBatConfig {
      home.shellAliases."cat" = "bat";

      programs.bat = {
        enable = mkDefault true;

        config = mkDefault {
          theme = "base16";
          italic-text = "always";
          style = "full";
        };
      };
    })

    (mkIf cfg.manageExaConfig {
      home.shellAliases = {
        "l" = "exa --classify --color=always --icons";
        "ls" = "exa --classify --color=always --icons";
        "la" = "exa --classify --color=always --icons --long --all --binary --group --header --git --color-scale";
        "ll" = "exa --classify --color=always --icons --long --all --binary --group --header --git --color-scale";
        "tree" = "exa --classify --color=always --icons --long --all --binary --group --header --git --color-scale --tree";
      };

      programs.exa.enable = true;
    })

    (mkIf cfg.manageLessConfig {
      home.shellAliases."more" = "less";

      # TODO: Figure out a lesskey config
      programs.less.enable = true;
    })

    (mkIf cfg.manageStarshipConfig {
      programs.starship = {
        enable = mkDefault true;

        package = mkDefault pkgs.starship;

        settings = mkDefault {
          add_newline = true;
          scan_timeout = 100;

          username = {
            format = "[$user]($style) in ";
            show_always = true;
            disabled = false;
          };

          hostname = {
            ssh_only = false;
            format = "⟨[$hostname](bold green)⟩ in ";
            disabled = false;
          };

          directory = {
            truncation_length = 3;
            fish_style_pwd_dir_length = 1;
          };

          shell = {
            disabled = false;
            bash_indicator = "bash";
            fish_indicator = "fish";
            powershell_indicator = "pwsh";
            elvish_indicator = "elvish";
            tcsh_indicator = "tcsh";
            xonsh_indicator = "xonsh";
            unknown_indicator = "?";
          };
        };
      };
    })

    (mkIf cfg.manageTmuxConfig {
      programs.tmux = mkIf cfg.manageTmuxConfig {
        enable = mkDefault true;
        clock24 = mkDefault true;
        keyMode = mkDefault "vi";
        prefix = mkDefault "C-a";
        shell = mkDefault (lib.getExe pkgs.zsh);

        plugins = with pkgs.tmuxPlugins; mkDefault [
          cpu
          prefix-highlight
          resurrect
        ];

        extraConfig = mkDefault ''
          # Configure looks
          set -g status on
          set -g status-fg 'colour15'
          set -g status-bg 'colour8'
          set -g status-left-length '100'
          set -g status-right-length '100'
          set -g status-position 'top'
          set -g status-left '#[fg=colour15,bold] #S '
          set -g status-right '#[fg=colour0,bg=colour8]#[fg=colour6,bg=colour0] %Y-%m-%d %H:%M '
          set-window-option -g status-fg 'colour15'
          set-window-option -g status-bg 'colour8'
          set-window-option -g window-status-separator ''''''
          set-window-option -g window-status-format '#[fg=colour15,bg=colour8] #I #W '
          set-window-option -g window-status-current-format '#[fg=colour8,bg=colour4]#[fg=colour0] #I  #W #[fg=colour4,bg=colour8]'
        '';
      };
    })

    (mkIf cfg.manageZshConfig {
      programs.zsh = {
        enable = mkDefault true;
        dotDir = ".config/zsh";
        shellGlobalAliases."UUID" = "$(uuidgen | tr -d \\n)";
        defaultKeymap = "viins";
        initExtra = mkIf config.sys.git.enable posixGitFunctions;
        enableAutosuggestions = true;

        oh-my-zsh = {
          enable = true;

          plugins = [
            "aliases"
            "aws"
            "colored-man-pages"
            "command-not-found"
            "docker"
            "encode64"
            "fd"
            "gh"
            "git"
            "git-auto-fetch"
            "git-extras"
            "git-flow"
            "git-lfs"
            "golang"
            "isodate"
            "python"
            "ripgrep"
            "rust"
            "systemd"
            "systemadmin"
            "tig"
            "terraform"
            "tmux"
            "urltools"
            "web-search"
          ];
        };

        plugins = [
          {
            name = "zsh-completions";
            src = pkgs.fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-completions";
              rev = "0.33.0";
              sha256 = "sha256-cQSKjQhhOm3Rvnx9V6LAmtuPp/ht/O0IimpunoQlQW8=";
            };
          }
          {
            name = "fast-syntax-highlighting";
            src = pkgs.zsh-fast-syntax-highlighting;
            file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
          }
          {
            name = "history-search-multi-word";
            src = pkgs.zsh-history-search-multi-word;
            file = "share/zsh/zsh-history-search-multi-word/history-search-multi-word.plugin.zsh";
          }
          {
            name = "you-should-use";
            src = pkgs.zsh-you-should-use;
            file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
          }
        ];

        history = {
          path = "${config.xdg.dataHome or "$XDG_DATA_HOME"}/zsh/zsh_history";
          size = 100000;
          save = 1000000;

          ignorePatterns = cfg.historyIgnore;

          expireDuplicatesFirst = true;
        };

        sessionVariables."ZSH_AUTOSUGGEST_USE_ASYNC" = "1";

        initExtraFirst = ''
          setopt AUTO_CD
          setopt PUSHD_IGNORE_DUPS
          setopt PUSHD_SILENT

          setopt ALWAYS_TO_END
          setopt AUTO_MENU
          setopt COMPLETE_IN_WORD
          setopt FLOW_CONTROL
          setopt PRINT_EXIT_VALUE
          setopt C_BASES

          # Additional History Options
          setopt INC_APPEND_HISTORY
          setopt HIST_IGNORE_ALL_DUPS
          setopt HIST_NO_STORE
          setopt HIST_REDUCE_BLANKS
          setopt HIST_VERIFY
        '';
      };
    })

    (mkIf cfg.zoxide {
      home.shellAliases = {
        "za" = "zoxide add";
        "zq" = "zoxide query";
        "zr" = "zoxide remove";

        "cd" = "z";
        "pushd" = "z";
        "popd" = "z -";
      };

      programs.zoxide.enable = true;
    })

    (mkIf cfg.fcp {
      home.packages = with pkgs; [ fcp ];
      home.shellAliases."cp" = mkForce "fcp";
    })
  ]);
}

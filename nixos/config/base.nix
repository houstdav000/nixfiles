{ config, lib, pkgs, ... }: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      dates = "weekly";
      persistent = true;
    };

    optimise.automatic = true;

    settings = {
      allowed-users = [ "@wheel" ];
      auto-optimise-store = true;

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment.etc."nix/nixpkgs-config.nix".text = lib.mkDefault ''
    {
      allowUnfree = ${lib.boolToString config.nixpkgs.config.allowUnfree};
    }
  '';

  environment = {
    defaultPackages = with pkgs; [
      aria
      bc
      cachix
      file
      git
      gnupg
      nix-index
      neofetch
      progress
      strace
      tree
      unzip
    ];

    homeBinInPath = true;
    localBinInPath = true;
  };

  services.logind.extraConfig = "IdleAction=Lock";

  programs.vim.defaultEditor = true;

  programs.tmux.enable = true;

  programs.mtr.enable = true;

  networking = {
    useDHCP = false;
    firewall.pingLimit = lib.mkIf config.networking.firewall.enable "--limit 1/minute --limit-burst 5";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Since apparently I can't trust people
  security.pki.caCertificateBlacklist = [
    ### Sites in countries I don't visit
    #
    "AC RAIZ FNMT-RCM SERVIDORES SEGUROS"
    "Autoridad de Certificacion Firmaprofesional CIF A62634068"
    "Camerfirma Chambers of Commerce Root"

    # China Financial Certification Authority
    "CFCA EV ROOT"

    # Chunghwa Telecom Co., Ltd
    "ePKI Root Certification Authority"
    "HiPKI Root CA - G1"

    # Dhimyotis
    "Certigna"
    "Certigna Root CA"

    # E-Tugra EBG A.S.
    "E-Tugra Global Root CA RSA v3"
    "E-Tugra Global Root CA ECC v3"

    # E-Tugra EBG Bilisim Teknolojileri ve Hizmetleri A.S.
    "E-Tugra Certification Authority"

    # GUANG DONG CERTIFICATE AUTHORITY
    "GDCA TrustAUTH R5 ROOT"

    # Hongkong Post
    "Hongkong Post Root CA 1"
    "Hongkong Post Root CA 3"

    # iTrusChina Co.,Ltd.
    "vTrus ECC Root CA"
    "vTrus Root CA"

    # Krajowa Izba Rozliczeniowa S.A.
    "SZAFIR ROOT CA2"

    # NetLock Kft.
    "NetLock Arany (Class Gold) Főtanúsítvány"

    # TAIWAN-CA
    "TWCA Root Certification Authority"
    "TWCA Global Root CA"

    # Turkiye
    "TUBITAK Kamu SM SSL Kok Sertifikasi - Surum 1"

    ### Malware/Misuse
    #
    "COMODO Certification Authority"
    "COMODO ECC Certification Authority"
    "COMODO RSA Certification Authority"
    "Comodo AAA Services root"

    ### Might be malicious
    #
    "TrustCor ECA-1"
    "TrustCor RootCert CA-1"
    "TrustCor RootCert CA-2"
  ];

  system.stateVersion = "22.11";
}

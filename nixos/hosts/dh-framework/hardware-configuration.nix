{ config, lib, pkgs, ... }: {
  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "sdhci_pci"
        "thunderbolt"
        "usb_storage"
        "usbcore"
        "xhci_pci"
      ];

      kernelModules = [
        "dm-snapshot"
        "i915"
        "kvm-intel"
        "nls_cp437"
        "nls_iso8859-1"
        "usbhid"
        "vfat"
      ];

      luks.devices."nixos-enc" = {
        device = "/dev/disk/by-partlabel/root";
        preLVM = true;
      };
    };

    kernel.sysctl."net.ipv4.conf.all.arp_filter" = 1;

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "intel_iommu=on"
      "quiet"
      "vga=current"
    ];
    plymouth.enable = true;

    extraModprobeConfig =
      let
        modopts = list: builtins.concatStringsSep " " ([ "options" ] ++ list);
      in
      modopts [
        "v412loopback"
        "video_nr=63"
        "kvm_intel"
        "nested=1"
      ];
    kernelModules = [ "v412loopback" ];
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  };

  fileSystems =
    let
      fsroot_subvol = subvol: {
        label = "fsroot";
        fsType = "btrfs";
        options = [ "subvol=${subvol}" ];
      };
    in
    {
      "/" = fsroot_subvol "root";
      "/home" = fsroot_subvol "home";
      "/nix" = fsroot_subvol "nix";

      "/boot" = {
        label = "boot";
        fsType = "vfat";
      };
    };

  zramSwap.enable = true;

  swapDevices = [ ];

  # Enable firmware upgrades
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.fwupd.enable = true;

  # Support Xbox One Controller
  hardware.xpadneo.enable = true;

  # Support mouse configuration
  services.ratbagd.enable = true;

  hardware.keyboard.zsa.enable = true;

  hardware.bluetooth = {
    enable = true;

    powerOnBoot = false;
    package = pkgs.bluezFull;
    settings.General.Name = config.networking.hostName;
  };

  hardware.opengl = {
    enable = true;

    driSupport32Bit = true;

    extraPackages = with pkgs; [
      beignet
      intel-media-driver
      libvdpau-va-gl
      mesa
      vaapiIntel
      vaapiVdpau
    ];

    extraPackages32 = with pkgs.driversi686Linux; [
      beignet
      libvdpau-va-gl
      mesa
      vaapiIntel
      vaapiVdpau
    ];
  };

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";
    };
  };
}

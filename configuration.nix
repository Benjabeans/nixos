# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{


  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./qylock.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  #enable experiment


  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;



  #TAILSCALE
  # 1. Enable the service and the firewall
  services.tailscale.enable = true;
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [ 
    "TS_DEBUG_FIREWALL_MODE=nftables" 
  ];

  # 3. Optimization: Prevent systemd from waiting for network online 
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false; 
  boot.initrd.systemd.network.wait-online.enable = false;





  # enable experimental
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  #GPU Nvidia Config
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;

    # Try true for newer NVIDIA GPUs. If build complains, change to false.
    open = true;
    nvidiaSettings = true;
  };


  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config.cudaSupport = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  
  #Configure zsh
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = ["git" "sudo" "history" ];
    };

  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };


  #hyprland
  programs.hyprland.enable = true; # enable Hyprland



  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.benjabeans = {
    isNormalUser = true;
    description = "Benjabeans";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [


    bibata-cursors

    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    neovim

    git
    fastfetch

    btop    
    wget

    kitty
    unzip

    gh
    glab

    
  ];


  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
   services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

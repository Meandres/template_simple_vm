# This configuration describes a template Linux VM image
{ lib, pkgs, kernelPackages, extraEnvPackages ? [], ... }:
with lib;
{
  networking = {
    hostName = "guest";
  };
  services.sshd.enable = true;
  networking.firewall.enable = true;

  users.users.root.password = "password";
  services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./keyfile.pub)
  ];
  services.getty.autologinUser = lib.mkDefault "root";

  fileSystems."/root" = {
      device = "home";
      fsType = "9p";
      options = [ "trans=virtio" "nofail" "msize=104857600" ];
  };

  # mount host nix store, but use overlay fs to make it writeable
  fileSystems."/nix/.ro-store-vmux" = {
    device = "nixstore";
    fsType = "9p";
    options = [ "ro" "trans=virtio" "nofail" "msize=104857600" ];
    neededForBoot = true;
  };
  fileSystems."/nix/store" = {
    device = "overlay";
    fsType = "overlay";
    options = [
      "lowerdir=/nix/.ro-store-vmux"
      "upperdir=/nix/.rw-store/store"
      "workdir=/nix/.rw-store/work"
    ];
    neededForBoot = true;
    depends = [
      "/nix/.ro-store-vmux"
      "/nix/.rw-store/store"
      "/nix/.rw-store/work"
    ];
  };
  boot.initrd.availableKernelModules = [ "overlay" ];

  nix.extraOptions = ''
      experimental-features = nix-command flakes
  '';
  nix.package = pkgs.nixFlakes;
  environment.systemPackages = [
    pkgs.vim
	  pkgs.git
	  pkgs.gnumake
    pkgs.just
    pkgs.python3
    kernelPackages.perf
  ] ++ extraEnvPackages;

  boot.kernelPackages = kernelPackages;

  system.stateVersion = "24.05";

  console.enable = true;
  #systemd.services."serial-getty@ttys0".enable = true;
  services.qemuGuest.enable = true;
}

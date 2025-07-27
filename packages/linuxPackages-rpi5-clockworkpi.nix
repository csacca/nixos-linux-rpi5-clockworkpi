{
  pkgs,
  perSystem,
  ...
}:
pkgs.linuxPackagesFor perSystem.self.linux-rpi5-clockworkpi

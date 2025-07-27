# packages/raspberrypifw.nix
{
  inputs,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib stdenvNoCC;
  inherit (inputs) rpi-firmware;
in
stdenvNoCC.mkDerivation {
  pname = "raspberrypifw"; # keep attribute name stable
  version = "git-" + lib.substring 0 7 (builtins.baseNameOf (toString rpi-firmware));

  src = rpi-firmware;

  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    mkdir -p $out/share/raspberrypi
    cp -R $src/boot $out/share/raspberrypi/
  '';

  meta = with lib; {
    description = "Firmware for Raspberry Pi (ClockworkPi uConsole override)";
    homepage = "https://github.com/raspberrypi/firmware";
    license = licenses.unfreeRedistributableFirmware;
    platforms = platforms.linux;
  };
}

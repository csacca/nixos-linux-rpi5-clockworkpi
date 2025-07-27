{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs) rpi-firmware-nonfree rpi-bluez-firmware;
  inherit (pkgs) lib stdenvNoCC;
in
stdenvNoCC.mkDerivation {
  pname = "raspberrypiWirelessFirmware";
  version = "git-" + lib.substring 0 7 (builtins.baseNameOf (toString rpi-firmware-nonfree));

  src = null;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/firmware/brcm"
    mkdir -p "$out/lib/firmware/cypress"

    # Wifi firmware
    cp -rv "${rpi-firmware-nonfree}/debian/config/brcm80211/." "$out/lib/firmware/"

    # Bluetooth firmware
    cp -rv "${rpi-bluez-firmware}/debian/firmware/broadcom/." "$out/lib/firmware/brcm"

    # brcmfmac43455-sdio.bin is a symlink to the non-existent path: ../cypress/cyfmac43455-sdio.bin.
    # See https://github.com/RPi-Distro/firmware-nonfree/issues/26
    pushd "$out/lib/firmware/cypress" &>/dev/null
    ln -s cyfmac43455-sdio-standard.bin cyfmac43455-sdio.bin
    popd &>/dev/null

    # Symlinks for Zero 2W
    pushd "$out/lib/firmware/brcm" &>/dev/null
    ln -s brcmfmac43436-sdio.clm_blob brcmfmac43430b0-sdio.clm_blob
    popd &>/dev/null

    runHook postInstall
  '';

  meta = with lib; {
    description = "Firmware for builtin Wifi/Bluetooth devices in the Raspberry Pi";
    homepage = "https://github.com/RPi-Distro/firmware-nonfree";
    license = licenses.unfreeRedistributableFirmware;
    platforms = platforms.linux;
    maintainers = with maintainers; [ lopsided98 ];
  };
}

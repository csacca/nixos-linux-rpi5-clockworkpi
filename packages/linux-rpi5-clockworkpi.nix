{
  pname,
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs) lib;
  inherit (lib) mkForce;

  # choose native vs cross tool-chain
  targetPkgs =
    if pkgs.stdenv.hostPlatform.isAarch64
    then pkgs
    else pkgs.pkgsCross.aarch64-multiplatform;

  # helpers to read kernel version fields from Makefile
  src = inputs.clockworkPiLinux; # ak-rex's patched rpi-6.12.y tree
  makefile = builtins.readFile "${src}/Makefile";

  # grab the first capture group from a regex
  field = pattern: let
    m = builtins.match pattern makefile;
  in
    if m == null
    then throw "Cannot find ${pattern} in Makefile"
    else lib.head m;

  VERSION = field ".+VERSION = ([0-9]+).+";
  PATCHLEVEL = field ".+PATCHLEVEL = ([0-9]+).+";
  SUBLEVEL = field ".+SUBLEVEL = ([0-9]+).+";
  EXTRAVERSION = let
    _extraversion = builtins.match ".+EXTRAVERSION = ([a-z0-9-]+).+" makefile;
  in
    if _extraversion == null
    then ""
    else lib.head _extraversion;

  modDirVersion = "${VERSION}.${PATCHLEVEL}.${SUBLEVEL}${EXTRAVERSION}-v8-16k";
  version = "${modDirVersion}-clockworkpi";

  # ── raw kernel derivation ────────────────────────────────────────────
  linux-rpi5-clockworkpi = targetPkgs.buildLinux {
    inherit lib pname version modDirVersion src;

    stdenv =
      targetPkgs.stdenv
      // {
        hostPlatform =
          targetPkgs.stdenv.hostPlatform
          // {
            # zero out the unwanted `extraConfig` string
            "linux-kernel" =
              targetPkgs.stdenv.hostPlatform.linux-kernel
              // {
                extraConfig = "";
              };
          };
      };

    defconfig = "bcm2712_defconfig";

    kernelPatches = [];
    structuredExtraConfig = with lib.kernel; {
      ACPI_APEI = mkForce unset;
      ACPI_APEI_GHES = mkForce unset;
      ACPI_DEBUG = mkForce unset;
      ACPI_FPDT = mkForce unset;
      ACPI_HMAT = mkForce unset;
      ACPI_HOTPLUG_CPU = mkForce unset;
      ACPI_HOTPLUG_MEMORY = mkForce unset;
      CGROUP_HUGETLB = mkForce unset;
      CHROMEOS_TBMC = mkForce unset;
      DRM_PANIC_SCREEN_QR_CODE = mkForce unset;
      DRM_VBOXVIDEO = mkForce unset;
      FSL_MC_UAPI_SUPPORT = mkForce unset;
      HOTPLUG_PCI_ACPI = mkForce unset;
      HOTPLUG_PCI_PCIE = mkForce unset;
      KEXEC_JUMP = mkForce unset;
      MOUSE_ELAN_I2C_SMBUS = mkForce unset;
      MOUSE_PS2_ELANTECH = mkForce unset;
      MT798X_WMAC = mkForce unset;
      NET_VENDOR_MEDIATEK = mkForce unset;
      NVME_AUTH = mkForce unset;
      PARAVIRT_SPINLOCKS = mkForce unset;
      PCI_TEGRA = mkForce unset;
      PCI_XEN = mkForce unset;
      PERF_EVENTS_AMD_BRS = mkForce unset;
      PINCTRL_AMD = mkForce unset;
      PM_WAKELOCKS = mkForce unset;
      RUST = mkForce unset;
      SCHED_CORE = mkForce unset;
      SUN8I_DE2_CCU = mkForce unset;
      USB_XHCI_TEGRA = mkForce unset;
      VBOXGUEST = mkForce unset;
      XEN_HAVE_PVMMU = mkForce unset;
      XEN_MCE_LOG = mkForce unset;
      XEN_PVH = mkForce unset;
      XEN_PVHVM = mkForce unset;
      XEN_SAVE_RESTORE = mkForce unset;
    };

    features = {
      efiBootStub = false; # we don’t boot via EFI
    };

    extraMeta = {
      branch = lib.versions.majorMinor version; # "6.12"
      description = "ClockworkPi uConsole vendor kernel (Raspberry Pi 6.12.y)";
      platforms = ["aarch64-linux"];
      hydraPlatforms = ["aarch64-linux"];
    };
  };

  # full kernel-packages set
  linuxPackages-rpi5-clockworkpi = targetPkgs.linuxPackagesFor linux-rpi5-clockworkpi;
in
  linuxPackages-rpi5-clockworkpi

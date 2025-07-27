{
  pname,
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs) lib;
  inherit (lib) mkForce;

  src = inputs.rpi-clockworkpi-linux;
  makefile = builtins.readFile "${src}/Makefile";

  field = pattern: let
    m = builtins.match pattern makefile;
  in
    if m == null
    then throw "Cannot find ${pattern} in Makefile"
    else lib.head m;

  VERSION = field ".+VERSION = ([0-9]+).+"; # 6
  PATCHLEVEL = field ".+PATCHLEVEL = ([0-9]+).+"; # 12
  SUBLEVEL = field ".+SUBLEVEL = ([0-9]+).+";
  EXTRAVERSION = let
    m = builtins.match ".+EXTRAVERSION = ([a-z0-9-]+).+" makefile;
  in
    if m == null
    then ""
    else lib.head m;

  modDirVersion = "${VERSION}.${PATCHLEVEL}.${SUBLEVEL}${EXTRAVERSION}-v8-16k";
  version = "${modDirVersion}-clockworkpi";

  linux-rpi5-clockworkpi = pkgs.buildLinux {
    inherit
      lib
      pname
      version
      modDirVersion
      src
      ;

    # ccacheStdenv    
    stdenv =
      pkgs.stdenv
      // {
        hostPlatform =
          pkgs.stdenv.hostPlatform
          // {
            # zero out the unwanted extraConfig string
            "linux-kernel" =
              pkgs.stdenv.hostPlatform.linux-kernel
              // {
                extraConfig = "";
              };
          };
      };

    defconfig = "bcm2712_defconfig";

    kernelPatches = with pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];

    structuredExtraConfig = with lib.kernel;
    # unset kernel options unknown in tree - fixes config errors
      {
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
      }
      // {
        # FB_SIMPLE = yes; # =unset in nixos;
        IP_PNP_DHCP = yes; # =unset in nixos;
        IP_PNP_RARP = yes; # =unset in nixos;
        LOGO_LINUX_MONO = no; # =unset in nixos;
        LOGO_LINUX_VGA16 = no; # =unset in nixos;
        ROOT_NFS = yes; # =unset in nixos;
      }
      //
      # reset some of the "_defconfig" kernel options after nixos
      # overrides some of them
      {
        # BINFMT_MISC = mkForce module ; # =yes in nixos;
        BRCMSTB_GISB_ARB = mkForce unset; # =module in nixos;
        CMA_SIZE_MBYTES = mkForce (freeform "5"); # =32 in nixos;
        CPU_FREQ_DEFAULT_GOV_ONDEMAND = mkForce yes; # =no in nixos;
        CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = mkForce no; # =yes in nixos;
        # CRYPTO_AES = mkForce module; # =yes in nixos;
        # CRYPTO_LIB_ARC4 = mkForce yes; # =module in nixos;
        # CRYPTO_SHA512 = mkForce module; # =yes in nixos;
        # DRM = mkForce module; # =yes in nixos;
        # EFI_VARS_PSTORE = mkForce unset; # =module in nixos;
        F2FS_FS = mkForce yes; # =module in nixos;
        # IKCONFIG = mkForce module; # =yes in nixos;
        # IPV6 = mkForce module; # =yes in nixos;
        IP_PNP = mkForce yes; # =no in nixos;
        # KEYBOARD_ATKBD = mkForce unset; # =module in nixos;
        LOGO = mkForce yes; # =unset in nixos;
        NET_CLS_BPF = mkForce yes; # =module in nixos;
        NFS_FS = mkForce yes; # =module in nixos;
        NFS_V2 = mkForce yes; # =module in nixos;
        NFS_V4 = mkForce yes; # =module in nixos;
        NLS_CODEPAGE_437 = mkForce yes; # =module in nixos;
        NR_CPUS = mkForce (freeform "4"); # =384 in nixos;
        PREEMPT = mkForce yes; # =no in nixos;
        # STRICT_DEVMEM = mkForce unset; # =yes in nixos;
        # UEVENT_HELPER = mkForce yes; # =no in nixos;
        # UNICODE = mkForce module; # =yes in nixos;
        # UPROBE_EVENTS = mkForce unset; # =yes in nixos;
        # USB_SERIAL = mkForce module; # =yes in nixos;
      }
      //
      # additional options
      {
        PREEMPT_VOLUNTARY = mkForce no;
      };

    features = {
      efiBootStub = false;
    };

    extraMeta = {
      branch = lib.versions.majorMinor version; # "6.12"
      description = "ClockworkPi vendor kernel (Raspberry Pi 6.12.y)";
      platforms = ["aarch64-linux"];
    };
  };
in
  linux-rpi5-clockworkpi

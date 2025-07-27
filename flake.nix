{
  description = "Simple flake with a devshell";

  # Add all your dependencies here
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    
    # ak-rex fork of raspberry pi kernel tree for ClockworkPi uConsole
    rpi-clockworkpi-linux = {
      # branch == "rpi-6.12.y"
      url = "github:ak-rex/ClockworkPi-linux/59b5c72214c967316b6de5916ef2ee63a17baee1";
      flake = false;
    };

    # Raspberry Pi firmware
    rpi-firmware = {
      url = "github:raspberrypi/firmware/7022a895240b2f853d9035ab61616b646caf7b3a";
      flake = false;
    };

    # Raspberry Pi firmware for wifi and bluetooth
    rpi-firmware-nonfree = {
      url = "github:RPi-Distro/firmware-nonfree/c9d3ae6584ab79d19a4f94ccf701e888f9f87a53";
      flake = false;
    };

    # Raspberry Pi firmware for bluetooth
    rpi-bluez-firmware = {
      url = "github:RPi-Distro/bluez-firmware/2bbfb8438e824f5f61dae3f6ebb367a6129a4d63";
      flake = false;
    };
  };

  # Load the blueprint
  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      systems = ["x86_64-linux" "aarch64-linux"];
    };
}

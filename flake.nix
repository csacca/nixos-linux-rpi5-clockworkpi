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

    clockworkPiLinux = {
      # branch == "rpi-6.12.y"
      url = "github:ak-rex/ClockworkPi-linux/85b196fde0dae6941e54290324e89d57b2d8ab90";
      flake = false;
    };
  };

  # Load the blueprint
  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      # systems = ["aarch64-linux"];
    };
}

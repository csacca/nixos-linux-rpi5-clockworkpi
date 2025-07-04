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
      url = "github:ak-rex/ClockworkPi-linux/59b5c72214c967316b6de5916ef2ee63a17baee1";
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

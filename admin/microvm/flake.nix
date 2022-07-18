# Example flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/unstable";
  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm }: {
    # Example nixosConfigurations entry
    nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Include the microvm module
        microvm.nixosModules.microvm
        # Add more modules here
        {
          networking.hostName = "my-microvm";
          microvm.hypervisor = "qemu";
          microvm.shares = [{
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }];

        }
      ];
    };

    packages.x86_64-linux.my-microvm = self.nixosConfigurations.my-microvm.config.declaredRunner;
  };
}

{
  description = "Flake for the SCION Internet Architecture";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-unstable"; };

  # Upstream source tree(s).
  inputs.scion-src = { type = "github"; owner = "netsec-ethz"; repo = "scion"; ref = "scionlab"; flake = false; };
  inputs.scion-apps-src = { type = "github"; owner = "netsec-ethz"; repo = "scion-apps"; flake = false; };
  inputs.scionlab-src = { type = "github"; owner = "netsec-ethz"; repo = "scionlab"; ref = "develop"; flake = false; };
  inputs.scion-builder-src = { type = "github"; owner = "netsec-ethz"; repo = "scion-builder"; flake = false; };

  inputs.rains-src = { type = "github"; owner = "netsec-ethz"; repo = "rains"; flake = false; };

  outputs = { self, nixpkgs, scion-src, scion-apps-src, scionlab-src, scion-builder-src, rains-src, ... }@inputs:
    let
      # Generate a user-friendly version numer.
      versions =
        let
          generateVersion = builtins.substring 0 8;
        in
        nixpkgs.lib.genAttrs
          [ "scion" "scion-apps" "scionlab" "scion-builder" "rains" ]
          (n: generateVersion inputs."${n}-src".lastModifiedDate);

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in
    {

      # A Nixpkgs overlay.
      overlay = final: prev: with final.pkgs; {

        scion = (callPackage ./pkgs/scion { }).overrideAttrs (_: {
          src = scion-src;
          version = versions.scion;
        });

        scion-systemd-wrapper = (callPackage ./pkgs/scion/systemd-wrapper.nix { }).overrideAttrs (_: {
          src = scion-builder-src + "/scion-systemd-wrapper";
          version = versions.scion-builder;
        });

        scion-apps = (callPackage ./pkgs/scion-apps { }).overrideAttrs (_: {
          src = scion-apps-src;
          version = versions.scion;
        });

        scionlab =
          ((callPackage ./pkgs/scionlab { }).override {
            python = python3;
          }).overrideAttrs (_: {
            src = scionlab-src + "/scionlab/hostfiles/scionlab-config";
            version = versions.scionlab;
          });

        rains = (callPackage ./pkgs/rains { }).overrideAttrs (_: {
          src = rains-src;
          version = versions.rains;
        });

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgSet = nixpkgsFor.${system};
        in
        {
          inherit (pkgSet)
            scion scion-apps scionlab
            scion-systemd-wrapper
            rains;
        }
      );

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.scion);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules = {
        scionlab = import ./modules/scionlab.nix;
        scion-apps = import ./modules/scion-apps;
        rains = import ./modules/rains.nix;
      };

      # NixOS system configuration, if applicable
      nixosConfigurations.scionlab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Hardcoded
        modules = [
          # VM-specific configuration
          ({ modulesPath, pkgs, ... }: {
            imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
            environment.systemPackages = with pkgs; [ feh chromium ];

            networking.hostName = "scionlab";
            networking.networkmanager.enable = true;

            services.xserver.enable = true;
            services.xserver.layout = "us";
            services.xserver.windowManager.i3.enable = true;
            services.xserver.displayManager.lightdm.enable = true;

            users.mutableUsers = false;
            users.users.scionlab = {
              password = "scionlab"; # yes, very secure, I know
              createHome = true;
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };
          })

          # SCIONLab support
          ({ ... }: {
            imports = [
              self.nixosModules.scionlab
              self.nixosModules.scion-apps
            ];

            nixpkgs.overlays = [ self.overlay ];
          })

          # SCIONLab configuration
          ({ ... }: {
              services.scionlab.enable = true;
              # Adjust to downloaded tarball path
              services.scionlab.configTarball = ./17-ffaa_1_db5.tar.gz;
              services.scionlab.identifier = "17-ffaa_1_db5-1";

              services.scion.apps.webapp.enable = true;
              services.scion.apps.bwtester.enable = true;
          })
        ];
      };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: self.packages.${system} // { });

    };
}

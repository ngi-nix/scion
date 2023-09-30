{
  description = "Flake for the SCION Internet Architecture";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-unstable"; };

  # Upstream source tree(s).
  inputs.scion-src = { type = "github"; owner = "scionproto"; repo = "scion"; ref = "v0.9.1"; flake = false; };

  inputs.scion-apps-src = { type = "github"; owner = "netsec-ethz"; repo = "scion-apps"; ref = "master"; flake = false; };
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

      apps = forAllSystems (system: {
        vm = {
          type = "app";
          program = "${self.nixosConfigurations.scionlab.config.system.build.vm}/bin/run-scionlab-vm";
        };
      });

      # A Nixpkgs overlay.
      overlay = final: prev: with final.pkgs; {

        scion = buildGoModule {
          pname = "scion";
          version = versions.scion;
          src = scion-src;
          vendorHash = "sha256-QoKOiFLOlNyS7SwTQ2hBfdiPTO9QOQb1SUzAOBduL+0=";

          excludedPackages = [ "acceptance" "demo" "tools" "pkg/private/xtest/graphupdater" ];

          doCheck = false;
        };

        scion-systemd-wrapper = stdenv.mkDerivation {
          pname = "scion-systemd-wrapper";
          version = versions.scion-builder;
          src = scion-builder-src + "/scion-systemd-wrapper";
          unpackPhase = ''
            runHook preUnpack
            cp $src scion-systemd-wrapper
            runHook postUnpack
          '';
          prePatch = ''
            sed -i 's@/bin/bash@${bash}/bin/bash@' scion-systemd-wrapper
          '';
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp scion-systemd-wrapper $out/bin
            runHook postInstall
          '';
        };

        scion-apps = buildGoModule {
          pname = "scion-apps";
          version = versions.scion-apps;
          src = scion-apps-src;
          postPatch = ''
            chmod 755 webapp/web/tests/health/*.sh
            patchShebangs webapp/web/tests/health
            substituteInPlace webapp/web/tests/health/scmpcheck.sh \
              --replace "hostname -I" "hostname -i"
          '';
          buildInputs = [ openpam ];
          vendorHash = "sha256-M19zcdKZbV530LfOqbOCjfB9xR95HLSfxsDG5Q8z0W8=";

          # Currently the Makefile for scion-apps will try to install _examples
	  buildPhase = ''
            runHook preBuild

            make scion-bat \
              scion-bwtestclient scion-bwtestserver \
              scion-netcat \
              scion-sensorfetcher scion-sensorserver \
              scion-skip \
              scion-ssh scion-sshd \
              scion-webapp \
              scion-web-gateway

            runHook postBuild
	  '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/{bin,share}
            cp bin/* $out/bin/
            cp -r webapp/web $out/share/scion-webapp
            runHook postInstall
          '';

        };

        scion-apps-examples = buildGoModule {
          pname = "scion-apps-examples";
          version = versions.scion-apps;
          src = scion-apps-src;
          modRoot = "_examples";

          vendorHash = "sha256-G7p/1lkTNBGUY+z08T/x8F4rCSPo5m5bEYoDAI8f/84=";

          postInstall = ''
            for f in $out/bin/*; do
              mv $f $out/bin/example-$(basename "$f")
            done
          '';

        };

        scionlab = stdenv.mkDerivation {
          pname = "scionlab";
          version = versions.scionlab;
          src = scionlab-src + "/scionlab/hostfiles/scionlab-config";
          unpackPhase = ''
            runHook preUnpack
            cp $src scionlab-config
            runHook postUnpack
          '';
          prePatch = ''
            sed -i 's@/usr/bin/env.*@${python3}/bin/python@' scionlab-config
          '';
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp scionlab-config $out/bin
            runHook postInstall
          '';
        };

        rains = buildGo117Module {
          pname = "rains";
          version = versions.rains;
          src = rains-src;
          vendorSha256 = "sha256-ppJ1Z4mVdJYl1sUIlFXbiTi6Mq16PH/0iWDIn5YMIp8=";
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgSet = nixpkgsFor.${system};
        in
        {
          inherit (pkgSet)
            scion scion-apps scion-apps-examples
            scionlab scion-systemd-wrapper
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
              services.scionlab.configTarball = ./19-ffaa_1_fe3.tar.gz;
              services.scionlab.identifier = "19-ffaa_0_1303";

              services.scion.apps.webapp.enable = true;
              services.scion.apps.bwtester.enable = true;
          })
        ];
      };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: self.packages.${system} // { });

    };
}

with nixpkgsFor.${system};
with self.packages.${system};
with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };
{

  scionlab-imagefetcher = makeTest {
    nodes.machine = { ... }: {
      imports = builtins.attrValues self.nixosModules;
      nixpkgs.overlays = [ self.overlay ];
      environment.systemPackages = [ self.packages.${system}.scion-apps ];

      services.scionlab.enable = true;
      services.scionlab.configTarball = ./18-ffaa.tar.gz;
      services.scionlab.v = "18-ffaa_1_d91-1";
    };

    testScript = ''
      start_all()

      machine.wait_for_unit("scion-dispatcher")
      machine.succeed(
          "scion-imagefetcher -s '17-ffaa:0:1102,[192.33.93.166]:42002' -output imagefetcher.jpg"
      )
      machine.succeed("stat imagefetcher.jpg")

      machine.shutdown()
    '';
  };

}
